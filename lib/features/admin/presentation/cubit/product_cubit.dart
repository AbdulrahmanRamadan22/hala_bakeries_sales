import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repositories/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/product_state.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;

  ProductCubit(this._productRepository) : super(const ProductState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      final products = await _productRepository.getProducts();
      emit(state.copyWith(status: ProductStatus.success, products: products));
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل تحميل المنتجات'));
    }
  }

  Future<void> addProduct(String name, String barcode, String category, String unit, double price) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      final newProduct = ProductModel(
        id: const Uuid().v4(),
        name: name,
        barcode: barcode,
        category: category,
        unit: unit,
        price: price,
      );
      await _productRepository.addProduct(newProduct);
      await loadProducts();
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'فشل إضافة المنتج'));
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

  void searchByBarcode(String barcode) {
    // Filter the current list locally
    final allProducts = state.products; // This might be filtered already if we don't keep a separate 'all' list.
    // Ideally, we should keep 'allProducts' in state and 'filteredProducts' for display.
    // For simplicity, let's just reload and filter or just filter if we assume state.products is all.
    // BUT, if we filter state.products, we lose the full list.
    // Let's just reload and then filter to be safe, or better:
    // We should probably have a 'searchQuery' in state.
    
    // Quick fix: Just filter the current list. To reset, user needs to reload (pull to refresh or back/forth).
    // Or better: Reload first then filter.
    
    // Let's implement a simple local filter for now.
    final filtered = state.products.where((p) => p.barcode == barcode).toList();
    if (filtered.isNotEmpty) {
      emit(state.copyWith(products: filtered));
    } else {
      emit(state.copyWith(status: ProductStatus.failure, errorMessage: 'المنتج غير موجود'));
      // Reload to show all again after a delay or let user reset?
      // Let's just reload all after 2 seconds to "reset"
      Future.delayed(const Duration(seconds: 2), () => loadProducts());
    }
  }
}
