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
      // 1. Load all products and branches first (fast)
      final products = await _productRepository.getProducts();
      final branches = await _branchRepository.getBranches();
      
      final List<LowStockItem> accumulatedItems = [];
      
      // 2. Process products in batches
      const batchSize = 10;
      for (var i = 0; i < products.length; i += batchSize) {
        final end = (i + batchSize < products.length) ? i + batchSize : products.length;
        final batch = products.sublist(i, end);
        
        // Thread-safe list for batch results
        final batchItems = <LowStockItem>[];
        
        // Process batch in parallel
        await Future.wait(batch.map((product) async {
          try {
            // Get stock for this product across all branches
            final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
            
            // Calculate total stock
            final totalStock = productBranchStocks.fold<int>(
              0, 
              (sum, stock) => sum + stock.currentStock,
            );

            // Check if product is low on stock
            if (totalStock <= product.minStockLevel) {
              final branchStockInfos = <BranchStockInfo>[];
              
              for (final branch in branches) {
                final branchStock = productBranchStocks
                    .where((stock) => stock.branchId == branch.id)
                    .firstOrNull;
                
                final currentStock = branchStock?.currentStock ?? 0;
                final isLow = currentStock <= product.minStockLevel;
                
                branchStockInfos.add(BranchStockInfo(
                  branchId: branch.id,
                  branchName: branch.name,
                  currentStock: currentStock,
                  isLow: isLow,
                ));
              }

              // Synchronized add to batch list is not needed since this is single-threaded event loop,
              // but we are inside Future.wait which awaits concurrent async operations.
              // However, 'batchItems' is local to this scope.
              // We should just return the item and filter nulls to be cleaner/safer.
              batchItems.add(LowStockItem(
                productId: product.id,
                productName: product.name,
                category: product.category,
                minStockLevel: product.minStockLevel,
                branchStocks: branchStockInfos,
                totalStock: totalStock,
              ));
            }
          } catch (e) {
            print('Error checking stock for ${product.name}: $e');
          }
        }));
        
        accumulatedItems.addAll(batchItems);
        
        // 3. Progressive Emission
        // Only emit if we have found items, OR if this is the very last batch
        if (accumulatedItems.isNotEmpty) {
          emit(state.copyWith(
            status: LowStockStatus.success,
            lowStockItems: List.from(accumulatedItems),
          ));
        }
      }

      // If finished and still empty, emit success with empty list (shows "No items" UI)
      if (accumulatedItems.isEmpty) {
        emit(state.copyWith(
          status: LowStockStatus.success,
          lowStockItems: [],
        ));
      }
      
    } catch (e) {
      print('LowStockCubit Error: $e');
      emit(state.copyWith(
        status: LowStockStatus.failure,
        errorMessage: 'فشل تحميل نواقص المخزون',
      ));
      
    }
  }
}
