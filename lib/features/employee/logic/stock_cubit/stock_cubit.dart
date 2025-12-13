import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/employee/logic/stock_cubit/stock_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';

class StockCubit extends Cubit<StockState> {
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final String branchId;

  StockCubit(
    this._productRepository,
    this._branchStockRepository,
    this.branchId,
  ) : super(const StockState());

  Future<void> loadStock() async {
    emit(state.copyWith(status: StockStatus.loading));
    try {
      print('Loading stock for branch: $branchId');
      
      // Get all products
      final products = await _productRepository.getProducts();
      print('Loaded ${products.length} products');
      
      // Get branch-specific stock
      final branchStocks = await _branchStockRepository.getBranchStocks(branchId);
      print('Loaded ${branchStocks.length} branch stocks');
      
      // Create stock items with branch-specific quantities
      final stockItems = products.map((p) {
        final branchStock = branchStocks.where((stock) => stock.productId == p.id).firstOrNull;
        
        return StockItem(
          product: p,
          quantity: (branchStock?.currentStock ?? 0).toDouble(),
          openingBalance: branchStock?.hasOpeningBalance == true ? branchStock!.currentStock.toDouble() : 0.0,
          lastUpdated: branchStock?.lastUpdated ?? DateTime.now(),
        );
      }).toList();

      print('Created ${stockItems.length} stock items');
      emit(state.copyWith(status: StockStatus.success, stockItems: stockItems));
    } catch (e) {
      print('StockCubit Error: $e');
      emit(state.copyWith(status: StockStatus.failure, errorMessage: 'فشل تحميل المخزون: $e'));
    }
  }
}
