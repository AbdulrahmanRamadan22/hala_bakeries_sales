import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final BranchRepository _branchRepository;

  ProductCubit(
    this._productRepository,
    this._branchStockRepository,
    this._branchRepository,
  ) : super(const ProductState());

  // Safe emit helper to prevent emitting after cubit is closed
  void safeEmit(ProductState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  Future<void> loadProducts({bool forceRefresh = false}) async {
    // If we already have products and not forcing refresh, skip
    if (!forceRefresh && state.products.isNotEmpty) {
      return;
    }

    safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري تحميل المنتجات...'));
    
    try {
      // Step 1: Load products quickly (without stock details)
      final products = await _productRepository.getProducts();
      
      // Emit products immediately for fast UI display
      safeEmit(state.copyWith(
        status: ProductStatus.success,
        products: products,
        productStocks: {}, // Empty initially
        branchStockDetails: {}, // Empty initially
      ));
      
      // Step 2: Load stock details in background (non-blocking)
      _loadStockDetailsInBackground(products);
      
    } catch (e) {
      print('ProductCubit Error: $e');
      safeEmit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل تحميل المنتجات'));
    }
  }

  /// Load stock details in background without blocking UI
  Future<void> _loadStockDetailsInBackground(List<ProductModel> products) async {
    try {
      print('ProductCubit: Loading stock details in background...');
      
      final branches = await _branchRepository.getBranches();
      final productStocks = <String, int>{};
      final branchStockDetails = <String, List<BranchStockDetail>>{};

      // Process products in batches for better performance
      const batchSize = 10;
      for (var i = 0; i < products.length; i += batchSize) {
        final end = (i + batchSize < products.length) ? i + batchSize : products.length;
        final batch = products.sublist(i, end);
        
        // Process batch in parallel
        await Future.wait(batch.map((product) async {
          try {
            final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
            
            // Calculate total
            final totalStock = productBranchStocks.fold<int>(
                0, (sum, stock) => sum + stock.currentStock);
            productStocks[product.id] = totalStock;

            // Create branch details
            final details = productBranchStocks.map((stock) {
              final branch = branches.where((b) => b.id == stock.branchId).firstOrNull;
              return BranchStockDetail(
                branchId: stock.branchId,
                branchName: branch?.name ?? 'فرع غير معروف',
                stock: stock.currentStock,
              );
            }).toList();

            branchStockDetails[product.id] = details;
          } catch (e) {
            print('ProductCubit: Error loading stock for product ${product.id}: $e');
            // Set default values on error
            productStocks[product.id] = 0;
            branchStockDetails[product.id] = [];
          }
        }));
        
        // Update UI after each batch
        safeEmit(state.copyWith(
          productStocks: Map.from(productStocks),
          branchStockDetails: Map.from(branchStockDetails),
        ));
      }
      
      print('ProductCubit: Finished loading stock details for ${products.length} products');
    } catch (e) {
      print('ProductCubit: Error loading stock details: $e');
      // Don't emit error - products are already displayed
    }
  }

  Future<void> addProduct(String name, String barcode, String category,
      String unit, double price, int minStockLevel) async {
    emit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري إضافة المنتج...'));
    try {
      // Check if barcode already exists
      if (barcode.isNotEmpty) {
        final barcodeExists =
            await _productRepository.checkBarcodeExists(barcode);
        if (barcodeExists) {
          emit(state.copyWith(
              status: ProductStatus.failure,
              errorMessage:
                  'الباركود "$barcode" موجود بالفعل لمنتج آخر. يجب أن يكون الباركود فريداً لكل منتج.'));
          return;
        }
      }

      final newProduct = ProductModel(
        id: const Uuid().v4(),
        name: name,
        barcode: barcode,
        category: category,
        unit: unit,
        price: price,
        minStockLevel: minStockLevel,
      );
      await _productRepository.addProduct(newProduct);
      await loadProducts(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل إضافة المنتج'));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    emit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري تحديث المنتج...'));
    try {
      // Check if barcode already exists for another product
      if (product.barcode.isNotEmpty) {
        final barcodeExists = await _productRepository
            .checkBarcodeExists(product.barcode, excludeProductId: product.id);
        if (barcodeExists) {
          emit(state.copyWith(
              status: ProductStatus.failure,
              errorMessage:
                  'الباركود "${product.barcode}" موجود بالفعل لمنتج آخر. يجب أن يكون الباركود فريداً لكل منتج.'));
          return;
        }
      }

      await _productRepository.updateProduct(product);
      await loadProducts(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل تحديث المنتج'));
    }
  }

  Future<void> deleteProduct(String id) async {
    emit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري حذف المنتج...'));
    try {
      await _productRepository.deleteProduct(id);
      await loadProducts(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل حذف المنتج'));
    }
  }

  Future<void> deleteAllProducts() async {
    emit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري حذف جميع المنتجات...'));
    try {
      final allProducts = await _productRepository.getProducts();
      for (final product in allProducts) {
        await _productRepository.deleteProduct(product.id);
      }
      await loadProducts(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل حذف المنتجات'));
    }
  }

  Future<void> importProductsFromExcel(String? targetBranchId, {bool importToAllBranches = false}) async {
    safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري فتح ملف Excel...'));
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        safeEmit(state.copyWith(
            status: ProductStatus.success)); // No file selected, just return
        return;
      }

      safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري قراءة ملف Excel...'));
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('ملف الإكسل فارغ');
      }

      safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري معالجة البيانات...'));
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.length < 2) {
        throw Exception(
            'الملف لا يحتوي على بيانات (يجب أن يحتوي على صف العناوين وصف واحد على الأقل)');
      }

      // Fetch all existing products to check for duplicates efficiently
      final existingProducts = await _productRepository.getProducts();
      final existingBarcodesMap = <String, String>{}; // barcode -> productId
      for (final product in existingProducts) {
        existingBarcodesMap[product.barcode] = product.id;
      }

      final newProducts = <ProductModel>[];
      final stockEntries = <String, int>{}; // productId -> quantity
      final seenBarcodesInFile = <String>{};

      int newCount = 0;
      int existingCount = 0; // Products that already exist (will add stock only)

      // Start from index 1 to skip header
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // Helper to get cell value safely
        String getCellValue(int index) {
          if (index >= row.length || row[index] == null) return '';
          return row[index]!.value.toString();
        }

        // Expected Columns: Barcode, Name, Category, Unit, Price, Stock, MinStock
        final barcode = getCellValue(0);
        final name = getCellValue(1);

        if (name.isEmpty || barcode.isEmpty) {
          print('Skipping row $i: Missing name or barcode');
          continue;
        }

        // Check for duplicates within the file itself
        if (seenBarcodesInFile.contains(barcode)) {
          print('Skipping row $i: Duplicate barcode in file: $barcode');
          continue;
        }
        seenBarcodesInFile.add(barcode);

        final stock = int.tryParse(getCellValue(5)) ?? 0;

        // Check if product already exists in database
        if (existingBarcodesMap.containsKey(barcode)) {
          // Product exists - just add stock for this branch
          final existingProductId = existingBarcodesMap[barcode]!;
          if (stock > 0) {
            stockEntries[existingProductId] = stock;
          }
          existingCount++;
          print('Product with barcode $barcode already exists. Adding stock to branch.');
        } else {
          // New product - create it
          final category = getCellValue(2);
          final unit = getCellValue(3).isEmpty ? 'piece' : getCellValue(3);
          final price = double.tryParse(getCellValue(4)) ?? 0.0;
          final minStock = int.tryParse(getCellValue(6)) ?? 5;

          final newProduct = ProductModel(
            id: const Uuid().v4(),
            barcode: barcode,
            name: name,
            category: category,
            unit: unit,
            price: price,
            minStockLevel: minStock,
          );

          newProducts.add(newProduct);
          existingBarcodesMap[barcode] = newProduct.id; // Add to map for file duplicates

          if (stock > 0) {
            stockEntries[newProduct.id] = stock;
          }
          newCount++;
        }
      }

      if (newProducts.isEmpty && stockEntries.isEmpty) {
        safeEmit(state.copyWith(
            status: ProductStatus.failure,
            errorMessage:
                'لم يتم استيراد أي منتجات أو مخزون. تأكد من البيانات في الملف.'));
        return;
      }

      // 1. Batch insert NEW products only
      if (newProducts.isNotEmpty) {
        safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري إضافة $newCount منتج جديد...'));
        await _productRepository.addProductsBatch(newProducts);
      }

      // 2. Set Opening Balance for products with stock
      if (stockEntries.isNotEmpty) {
        if (importToAllBranches) {
          // Import to ALL branches
          safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري تسجيل المخزون لجميع الفروع...'));
          final allBranches = await _branchRepository.getBranches();
          
          for (final branch in allBranches) {
            final branchStockFutures = stockEntries.entries.map((entry) {
              return _branchStockRepository.setOpeningBalance(
                  branchId: branch.id, 
                  productId: entry.key, 
                  quantity: entry.value
              );
            });
            await Future.wait(branchStockFutures);
          }
          
          print('Stock set for ${allBranches.length} branches');
        } else {
          // Import to single branch
          safeEmit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري تسجيل المخزون الابتدائي...'));
          final stockFutures = stockEntries.entries.map((entry) {
            return _branchStockRepository.setOpeningBalance(
                branchId: targetBranchId!, 
                productId: entry.key, 
                quantity: entry.value
            );
          });
          await Future.wait(stockFutures);
        }
      }

      await loadProducts(forceRefresh: true);

      // We can use a special state or a one-off event to show success message,
      // but for now we'll just reload. Ideally we should show a specific success message.
      print(
          'ProductCubit: Import complete. New: $newCount, Existing: $existingCount, Stock entries: ${stockEntries.length}');
    } catch (e, stackTrace) {
      print('ProductCubit Import Error: $e');
      print('StackTrace: $stackTrace');
      safeEmit(state.copyWith(
          status: ProductStatus.failure,
          errorMessage: 'فشل استيراد المنتجات: ${e.toString()}'));
    }
  }

  void searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    emit(state.copyWith(status: ProductStatus.loading, loadingMessage: 'جاري البحث...'));
    try {
      final allProducts = await _productRepository.getProducts();
      final branches = await _branchRepository.getBranches();

      // Filter products by name or barcode
      final trimmedQuery = query.trim().toLowerCase();
      final filtered = allProducts.where((p) {
        return p.name.toLowerCase().contains(trimmedQuery) ||
            p.barcode.toLowerCase().contains(trimmedQuery);
      }).toList();

      // Fetch stock details for filtered products
      final productStocks = <String, int>{};
      final branchStockDetails = <String, List<BranchStockDetail>>{};

      for (final product in filtered) {
        final productBranchStocks =
            await _branchStockRepository.getProductStocks(product.id);

        final totalStock = productBranchStocks.fold<int>(
            0, (sum, stock) => sum + stock.currentStock);
        productStocks[product.id] = totalStock;

        final details = productBranchStocks.map((stock) {
          final branch =
              branches.where((b) => b.id == stock.branchId).firstOrNull;
          return BranchStockDetail(
            branchId: stock.branchId,
            branchName: branch?.name ?? 'فرع غير معروف',
            stock: stock.currentStock,
          );
        }).toList();

        branchStockDetails[product.id] = details;
      }

      emit(state.copyWith(
        status: ProductStatus.success,
        products: filtered,
        productStocks: productStocks,
        branchStockDetails: branchStockDetails,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, errorMessage: 'فشل البحث'));
    }
  }
}
