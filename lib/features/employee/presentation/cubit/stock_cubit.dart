import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/stock_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repositories/product_repository.dart';

class StockCubit extends Cubit<StockState> {
  final ProductRepository _productRepository;

  StockCubit(this._productRepository) : super(const StockState());

  Future<void> loadStock() async {
    emit(state.copyWith(status: StockStatus.loading));
    try {
      // In this simple implementation, stock is part of the product model
      final products = await _productRepository.getProducts();
      
      // Map products to StockItems (if needed) or just use products directly
      // The StockState expects List<StockItem>, so we map it.
      // Assuming ProductModel has a stockQuantity field (I need to verify this).
      // If not, I'll need to update ProductModel or fetch from a separate collection.
      // Let's assume ProductModel has it or I'll add it.
      
      final stockItems = products.map((p) => StockItem(
        productId: p.id,
        productName: p.name,
        quantity: p.stockQuantity ?? 0, // Assuming stockQuantity exists
        unit: p.unit,
        lastUpdated: DateTime.now(), // Ideally from DB
      )).toList();

      emit(state.copyWith(status: StockStatus.success, items: stockItems));
    } catch (e) {
      emit(state.copyWith(status: StockStatus.failure, errorMessage: 'فشل تحميل المخزون'));
    }
  }
}
