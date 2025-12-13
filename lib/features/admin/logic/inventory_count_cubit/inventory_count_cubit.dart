import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_count_cubit/inventory_count_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_item_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/inventory_count_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

class InventoryCountCubit extends Cubit<InventoryCountState> {
  final InventoryCountRepository _inventoryCountRepository;
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final TransactionRepository _transactionRepository;

  InventoryCountCubit({
    required InventoryCountRepository inventoryCountRepository,
    required ProductRepository productRepository,
    required BranchStockRepository branchStockRepository,
    required TransactionRepository transactionRepository,
  })  : _inventoryCountRepository = inventoryCountRepository,
        _productRepository = productRepository,
        _branchStockRepository = branchStockRepository,
        _transactionRepository = transactionRepository,
        super(const InventoryCountState());

  /// Check if current time is within inventory count window (1-3 AM)
  bool isWithinTimeWindow() {
    return true;
  }

  /// Check if user can edit inventory count
  bool canEdit(InventoryCountModel? count, UserModel user) {
    if (user.role == UserRole.admin) return true;
    if (count == null) return false;
    if (count.employeeId != user.id) return false;
    return count.canBeEditedByEmployee();
  }

  /// Initialize inventory count for a branch
  Future<void> initializeInventoryCount({
    required String branchId,
    required String branchName,
    required UserModel user,
  }) async {
    try {
      emit(state.copyWith(
        status: InventoryCountStatus.loading,
        isWithinTimeWindow: isWithinTimeWindow(),
      ));

      // Check if count already exists for today
      final existingCount = await _inventoryCountRepository.getTodayInventoryCount(branchId);
      
      if (existingCount != null) {
        print('🔄 Refreshing existing count data...');
        // Refresh transaction data for existing count
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endDate = now;
        
        print('   Date range: $startOfToday to $endDate');
        
        final List<InventoryCountItem> refreshedItems = [];
        
        for (var item in existingCount.items) {
          print('   Processing: ${item.productName} (${item.productId})');
          
          // Get current received quantity
          final receivedTransactions = await _getTransactionsByType(
            branchId: branchId,
            productId: item.productId,
            type: TransactionType.receive,
            startDate: startOfToday,
            endDate: endDate,
          );
          final receivedQuantity = receivedTransactions.fold<int>(
            0,
            (sum, t) => sum + t.quantity.toInt(),
          );
          print('      Received: $receivedQuantity (${receivedTransactions.length} transactions)');

          // Get current damaged quantity
          final damagedTransactions = await _getTransactionsByType(
            branchId: branchId,
            productId: item.productId,
            type: TransactionType.damage,
            startDate: startOfToday,
            endDate: endDate,
          );
          final damagedQuantity = damagedTransactions.fold<int>(
            0,
            (sum, t) => sum + t.quantity.toInt(),
          );
          print('      Damaged: $damagedQuantity (${damagedTransactions.length} transactions)');

          // Create refreshed item with updated transaction data
          final refreshedItem = InventoryCountItem.create(
            productId: item.productId,
            productName: item.productName,
            barcode: item.barcode,
            unitPrice: item.unitPrice,
            openingBalance: item.openingBalance,
            receivedQuantity: receivedQuantity,
            damagedQuantity: damagedQuantity,
            actualQuantity: item.actualQuantity,
            note: item.note,
          );
          
          refreshedItems.add(refreshedItem);
        }
        
        print('✅ Refresh complete. Items: ${refreshedItems.length}');
        
        // Load existing count with refreshed items
        emit(state.copyWith(
          status: InventoryCountStatus.loaded,
          currentCount: existingCount,
          items: refreshedItems,
          canEdit: canEdit(existingCount, user),
        ));
        return;
      }

      // Load products for the branch
      final products = await _productRepository.getProducts();
      
      // Get transactions from start of today to now
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endDate = now; // Current moment

      // Create items with calculated expected quantities
      final List<InventoryCountItem> items = [];

      for (var product in products) {
        // Get current stock (live value from system)
        final branchStock = await _branchStockRepository.getBranchStock(branchId, product.id);
        final currentStock = branchStock?.currentStock ?? 0;

        // Get received quantity today
        final receivedTransactions = await _getTransactionsByType(
          branchId: branchId,
          productId: product.id,
          type: TransactionType.receive,
          startDate: startOfToday,
          endDate: endDate,
        );
        final receivedQuantity = receivedTransactions.fold<int>(
          0,
          (sum, t) => sum + t.quantity.toInt(),
        );

        // Get damaged quantity today
        final damagedTransactions = await _getTransactionsByType(
          branchId: branchId,
          productId: product.id,
          type: TransactionType.damage,
          startDate: startOfToday,
          endDate: endDate,
        );
        final damagedQuantity = damagedTransactions.fold<int>(
          0,
          (sum, t) => sum + t.quantity.toInt(),
        );

        // Calculate Opening Balance (Start of Day)
        // Opening = Current - Received + Damaged
        // This ensures that Expected (Opening + Received - Damaged) equals Current Stock
        final openingBalance = currentStock - receivedQuantity + damagedQuantity;

        // Create item with actual quantity = 0 (to be filled by user)
        final item = InventoryCountItem.create(
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          unitPrice: product.price,
          openingBalance: openingBalance,
          receivedQuantity: receivedQuantity,
          damagedQuantity: damagedQuantity,
          actualQuantity: 0,
        );

        items.add(item);
      }

      emit(state.copyWith(
        status: InventoryCountStatus.loaded,
        items: items,
        canEdit: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryCountStatus.error,
        errorMessage: 'فشل في تحميل بيانات الجرد: $e',
      ));
    }
  }

  /// Helper to refresh items with latest transaction data
  Future<List<InventoryCountItem>> _refreshItemsWithLatestTransactions(
    List<InventoryCountItem> items,
    String branchId,
  ) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endDate = now;

    final List<InventoryCountItem> refreshedItems = [];

    for (var item in items) {
      // Get current received quantity
      final receivedTransactions = await _getTransactionsByType(
        branchId: branchId,
        productId: item.productId,
        type: TransactionType.receive,
        startDate: startOfToday,
        endDate: endDate,
      );
      final receivedQuantity = receivedTransactions.fold<int>(
        0,
        (sum, t) => sum + t.quantity.toInt(),
      );

      // Get current damaged quantity
      final damagedTransactions = await _getTransactionsByType(
        branchId: branchId,
        productId: item.productId,
        type: TransactionType.damage,
        startDate: startOfToday,
        endDate: endDate,
      );
      final damagedQuantity = damagedTransactions.fold<int>(
        0,
        (sum, t) => sum + t.quantity.toInt(),
      );

      // Create refreshed item
      refreshedItems.add(InventoryCountItem.create(
        productId: item.productId,
        productName: item.productName,
        barcode: item.barcode,
        unitPrice: item.unitPrice,
        openingBalance: item.openingBalance,
        receivedQuantity: receivedQuantity,
        damagedQuantity: damagedQuantity,
        actualQuantity: item.actualQuantity,
        note: item.note,
      ));
    }
    return refreshedItems;
  }

  /// Get transactions by type and date range
  Future<List<TransactionModel>> _getTransactionsByType({
    required String branchId,
    required String productId,
    required TransactionType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('branchId', isEqualTo: branchId)
          .where('productId', isEqualTo: productId)
          .where('type', isEqualTo: type.name)
          .get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .where((t) => 
            (t.timestamp.isAfter(startDate) || t.timestamp.isAtSameMomentAs(startDate)) &&
            (t.timestamp.isBefore(endDate) || t.timestamp.isAtSameMomentAs(endDate))
          )
          .toList();

      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Update actual quantity for a product
  void updateActualQuantity(String productId, int actualQuantity, {String? note}) {
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(actualQuantity: actualQuantity, note: note);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
  }

  /// Update actual quantity by barcode
  void updateActualQuantityByBarcode(String barcode, int actualQuantity, {String? note}) {
    final item = state.items.firstWhere(
      (item) => item.barcode == barcode,
      orElse: () => state.items.first,
    );

    if (item.barcode == barcode) {
      updateActualQuantity(item.productId, actualQuantity, note: note);
    }
  }

  /// Save inventory count (draft)
  Future<void> saveInventoryCount({
    required String branchId,
    required String branchName,
    required UserModel user,
    String? notes,
  }) async {
    try {
      emit(state.copyWith(status: InventoryCountStatus.saving));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Refresh items with latest transaction data before saving
      final refreshedItems = await _refreshItemsWithLatestTransactions(
        state.items,
        branchId,
      );

      final count = InventoryCountModel.create(
        id: state.currentCount?.id ?? const Uuid().v4(),
        date: today,
        branchId: branchId,
        branchName: branchName,
        employeeId: user.id,
        employeeName: user.name,
        createdAt: state.currentCount?.createdAt ?? now,
        updatedAt: now,
        items: refreshedItems,
        notes: notes,
        status: 'draft',
      );

      if (state.currentCount == null) {
        await _inventoryCountRepository.createInventoryCount(count);
      } else {
        await _inventoryCountRepository.updateInventoryCount(count);
      }

      emit(state.copyWith(
        status: InventoryCountStatus.success,
        currentCount: count,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryCountStatus.error,
        errorMessage: 'فشل في حفظ الجرد: $e',
      ));
    }
  }

  /// Submit inventory count (final)
  Future<void> submitInventoryCount({
    required String branchId,
    required String branchName,
    required UserModel user,
    String? notes,
  }) async {
    try {
      emit(state.copyWith(status: InventoryCountStatus.saving));

      // Validate that all items have been counted
      final hasUncountedItems = state.items.any((item) => item.actualQuantity == 0);
      if (hasUncountedItems) {
        emit(state.copyWith(
          status: InventoryCountStatus.error,
          errorMessage: 'يجب جرد جميع المنتجات قبل الإرسال',
        ));
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Refresh items with latest transaction data before saving
      final refreshedItems = await _refreshItemsWithLatestTransactions(
        state.items,
        branchId,
      );

      final count = InventoryCountModel.create(
        id: state.currentCount?.id ?? const Uuid().v4(),
        date: today,
        branchId: branchId,
        branchName: branchName,
        employeeId: user.id,
        employeeName: user.name,
        createdAt: state.currentCount?.createdAt ?? now,
        updatedAt: now,
        items: refreshedItems,
        notes: notes,
        status: 'completed',
      );

      if (state.currentCount == null) {
        await _inventoryCountRepository.createInventoryCount(count);
      } else {
        await _inventoryCountRepository.updateInventoryCount(count);
      }

      // Update opening balance for next day
      await _updateOpeningBalances(branchId, state.items, user);

      emit(state.copyWith(
        status: InventoryCountStatus.success,
        currentCount: count,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryCountStatus.error,
        errorMessage: 'فشل في إرسال الجرد: $e',
      ));
    }
  }

  /// Update opening balances based on actual count
  Future<void> _updateOpeningBalances(
    String branchId,
    List<InventoryCountItem> items,
    UserModel user,
  ) async {
    for (var item in items) {
      try {
        // Get current stock before update
        final stock = await _branchStockRepository.getBranchStock(branchId, item.productId);
        
        if (stock != null) {
          final beforeStock = stock.currentStock;
          final afterStock = item.actualQuantity;
          
          // Calculate sales from variance
          // Sales = (Opening + Received - Damaged) - Actual
          final expectedStock = item.expectedQuantity;
          final variance = expectedStock - afterStock;
          
          // If variance is positive, it means items were sold or lost
          if (variance > 0) {
            // Record as sales transaction
            final salesTransaction = TransactionModel(
              id: const Uuid().v4(),
              type: TransactionType.sale,
              branchId: branchId,
              productId: item.productId,
              userId: user.id,
              quantity: variance.toDouble(),
              timestamp: DateTime.now(),
              notes: 'مبيعات محسوبة من الجرد اليومي${item.note != null && item.note!.isNotEmpty ? ' - ${item.note}' : ''}',
              beforeStock: beforeStock.toDouble(),
              afterStock: afterStock.toDouble(),
            );
            await _transactionRepository.addTransaction(salesTransaction);
          } else if (variance < 0) {
            // If variance is negative, it means there's an unexpected increase
            // Log as adjustment
            final adjustmentTransaction = TransactionModel(
              id: const Uuid().v4(),
              type: TransactionType.adjustment,
              branchId: branchId,
              productId: item.productId,
              userId: user.id,
              quantity: variance.abs().toDouble(),
              timestamp: DateTime.now(),
              notes: 'زيادة غير متوقعة من الجرد اليومي${item.note != null && item.note!.isNotEmpty ? ': ${item.note}' : ''}',
              beforeStock: beforeStock.toDouble(),
              afterStock: afterStock.toDouble(),
            );
            await _transactionRepository.addTransaction(adjustmentTransaction);
          }
          
          // Update branch stock to actual quantity
          final updatedStock = stock.copyWith(
            currentStock: afterStock,
            lastUpdated: DateTime.now(),
          );
          await _branchStockRepository.setBranchStock(updatedStock);
        }
      } catch (e) {
        // Continue with other items even if one fails
        print('Failed to update stock for ${item.productName}: $e');
      }
    }
  }

  /// Load historical inventory counts
  Future<void> loadHistoricalCounts(String branchId) async {
    try {
      final counts = await _inventoryCountRepository.getInventoryCountsByBranch(branchId);
      emit(state.copyWith(historicalCounts: counts));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryCountStatus.error,
        errorMessage: 'فشل في تحميل السجلات: $e',
      ));
    }
  }

  /// Load specific inventory count
  Future<void> loadInventoryCount(String countId, UserModel user) async {
    try {
      emit(state.copyWith(status: InventoryCountStatus.loading));

      final count = await _inventoryCountRepository.getInventoryCountById(countId);
      
      if (count == null) {
        emit(state.copyWith(
          status: InventoryCountStatus.error,
          errorMessage: 'الجرد غير موجود',
        ));
        return;
      }

      emit(state.copyWith(
        status: InventoryCountStatus.loaded,
        currentCount: count,
        items: count.items,
        canEdit: canEdit(count, user),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryCountStatus.error,
        errorMessage: 'فشل في تحميل الجرد: $e',
      ));
    }
  }

  /// Reset state
  void reset() {
    emit(const InventoryCountState());
  }
}
