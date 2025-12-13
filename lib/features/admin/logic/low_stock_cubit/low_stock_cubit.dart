import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/low_stock_cubit/low_stock_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';

class LowStockCubit extends Cubit<LowStockState> {
  final ProductRepository _productRepository;
  final BranchRepository _branchRepository;
  final BranchStockRepository _branchStockRepository;

  LowStockCubit(
    this._productRepository,
    this._branchRepository,
    this._branchStockRepository,
  ) : super(const LowStockState());

  Future<void> loadLowStockItems() async {
    emit(state.copyWith(status: LowStockStatus.loading));
    
    try {
      final products = await _productRepository.getProducts();
      final branches = await _branchRepository.getBranches();
      
      final List<LowStockItem> lowStockItems = [];

      for (final product in products) {
        // Get stock for this product across all branches
        final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
        
        // Calculate total stock
        final totalStock = productBranchStocks.fold<int>(
          0, 
          (sum, stock) => sum + stock.currentStock,
        );

        // Check if product is low on stock (total stock <= minStockLevel)
        if (totalStock <= product.minStockLevel) {
          // Create branch stock info list
          final branchStockInfos = <BranchStockInfo>[];
          
          for (final branch in branches) {
            // Find stock for this branch, default to 0 if not found
            final branchStock = productBranchStocks
                .where((stock) => stock.branchId == branch.id)
                .firstOrNull;
            
            final currentStock = branchStock?.currentStock ?? 0;
            
            // Check if this specific branch has low stock
            final isLow = currentStock <= product.minStockLevel;
            
            branchStockInfos.add(BranchStockInfo(
              branchId: branch.id,
              branchName: branch.name,
              currentStock: currentStock,
              isLow: isLow,
            ));
          }

          lowStockItems.add(LowStockItem(
            productId: product.id,
            productName: product.name,
            category: product.category,
            minStockLevel: product.minStockLevel,
            branchStocks: branchStockInfos,
            totalStock: totalStock,
          ));
        }
      }

      emit(state.copyWith(
        status: LowStockStatus.success,
        lowStockItems: lowStockItems,
      ));
    } catch (e) {
      print('LowStockCubit Error: $e');
      emit(state.copyWith(
        status: LowStockStatus.failure,
        errorMessage: 'فشل تحميل نواقص المخزون',
      ));
    }
  }
}
