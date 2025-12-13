import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final BranchRepository _branchRepository;

  ProductCubit(
    this._productRepository,
    this._branchStockRepository,
    this._branchRepository,
  ) : super(const ProductState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      final products = await _productRepository.getProducts();
      final branches = await _branchRepository.getBranches();
      
      // Fetch total stock and branch details for each product
      final productStocks = <String, int>{};
      final branchStockDetails = <String, List<BranchStockDetail>>{};
      
      for (final product in products) {
        // Get stock for this product across all branches
        final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
        
        // Calculate total
        final totalStock = productBranchStocks.fold<int>(0, (sum, stock) => sum + stock.currentStock);
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
      }
      
      emit(state.copyWith(
        status: ProductStatus.success,
        products: products,
        productStocks: productStocks,
        branchStockDetails: branchStockDetails,
      ));
    } catch (e) {
      print('ProductCubit Error: $e');
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل تحميل المنتجات'));
    }
  }

  Future<void> addProduct(String name, String barcode, String category, String unit, double price, int minStockLevel) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      // Check if barcode already exists
      if (barcode.isNotEmpty) {
        final barcodeExists = await _productRepository.checkBarcodeExists(barcode);
        if (barcodeExists) {
          emit(state.copyWith(
            status: ProductStatus.failure, 
            errorMessage: 'الباركود "$barcode" موجود بالفعل لمنتج آخر. يجب أن يكون الباركود فريداً لكل منتج.'
          ));
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
      await loadProducts();
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل إضافة المنتج'));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      // Check if barcode already exists for another product
      if (product.barcode.isNotEmpty) {
        final barcodeExists = await _productRepository.checkBarcodeExists(
          product.barcode, 
          excludeProductId: product.id
        );
        if (barcodeExists) {
          emit(state.copyWith(
            status: ProductStatus.failure, 
            errorMessage: 'الباركود "${product.barcode}" موجود بالفعل لمنتج آخر. يجب أن يكون الباركود فريداً لكل منتج.'
          ));
          return;
        }
      }
      
      await _productRepository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل تحديث المنتج'));
    }
  }

  Future<void> deleteProduct(String id) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      await _productRepository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل حذف المنتج'));
    }
  }

  void searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    emit(state.copyWith(status: ProductStatus.loading));
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
        final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
        
        final totalStock = productBranchStocks.fold<int>(0, (sum, stock) => sum + stock.currentStock);
        productStocks[product.id] = totalStock;
        
        final details = productBranchStocks.map((stock) {
          final branch = branches.where((b) => b.id == stock.branchId).firstOrNull;
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
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل البحث'));
    }
  }
}
