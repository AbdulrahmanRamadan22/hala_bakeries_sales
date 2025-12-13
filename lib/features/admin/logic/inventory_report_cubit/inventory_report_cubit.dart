import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_report_cubit/inventory_report_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/inventory_count_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_item_model.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';

class InventoryReportCubit extends Cubit<InventoryReportState> {
  final InventoryCountRepository _inventoryCountRepository;

  InventoryReportCubit({
    required InventoryCountRepository inventoryCountRepository,
  })  : _inventoryCountRepository = inventoryCountRepository,
        super(const InventoryReportState());

  /// Fetch inventory reports with optional filters
  Future<void> fetchReports({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    try {
      emit(state.copyWith(
        status: InventoryReportStatus.loading,
        startDate: startDate,
        endDate: endDate,
        selectedBranchId: branchId,
      ));

      List<InventoryCountModel> reports;

      if (startDate != null && endDate != null) {
        // Fetch by date range
        reports = await _inventoryCountRepository.getInventoryCountsByDateRange(
          startDate: startDate,
          endDate: endDate,
          branchId: branchId,
        );
      } else if (branchId != null) {
        // Fetch by branch only
        reports = await _inventoryCountRepository.getInventoryCountsByBranch(branchId);
      } else {
        // Fetch all
        reports = await _inventoryCountRepository.getAllInventoryCounts();
      }

      // Refresh transaction data for all reports
      final refreshedReports = <InventoryCountModel>[];
      for (var report in reports) {
        refreshedReports.add(await _refreshReportData(report));
      }
      reports = refreshedReports;

      // Calculate summary statistics
      final stats = _calculateSummaryStats(reports);

      emit(state.copyWith(
        status: InventoryReportStatus.loaded,
        reports: reports,
        totalCounts: stats['totalCounts'] as int,
        totalExpectedValue: stats['totalExpectedValue'] as double,
        totalActualValue: stats['totalActualValue'] as double,
        netVarianceValue: stats['netVarianceValue'] as double,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryReportStatus.error,
        errorMessage: 'فشل في تحميل التقارير: $e',
      ));
    }
  }

  /// Calculate summary statistics from reports
  Map<String, dynamic> _calculateSummaryStats(List<InventoryCountModel> reports) {
    int totalCounts = reports.length;
    double totalExpectedValue = 0.0;
    double totalActualValue = 0.0;

    for (var report in reports) {
      for (var item in report.items) {
        totalExpectedValue += item.expectedQuantity * item.unitPrice;
        totalActualValue += item.actualQuantity * item.unitPrice;
      }
    }

    final netVarianceValue = totalActualValue - totalExpectedValue;

    return {
      'totalCounts': totalCounts,
      'totalExpectedValue': totalExpectedValue,
      'totalActualValue': totalActualValue,
      'netVarianceValue': netVarianceValue,
    };
  }

  /// Update date filter
  void updateDateFilter(DateTime? startDate, DateTime? endDate) {
    fetchReports(
      startDate: startDate,
      endDate: endDate,
      branchId: state.selectedBranchId,
    );
  }

  /// Update branch filter
  void updateBranchFilter(String? branchId) {
    fetchReports(
      startDate: state.startDate,
      endDate: state.endDate,
      branchId: branchId,
    );
  }

  /// Refresh report data with latest transactions
  Future<InventoryCountModel> _refreshReportData(InventoryCountModel report) async {
    final startOfDay = DateTime(report.date.year, report.date.month, report.date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)); // Start of next day

    final refreshedItems = <InventoryCountItem>[];

    for (var item in report.items) {
      // Get received quantity
      final receivedTransactions = await _getTransactionsByType(
        branchId: report.branchId,
        productId: item.productId,
        type: TransactionType.receive,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      final receivedQuantity = receivedTransactions.fold<int>(
        0,
        (sum, t) => sum + t.quantity.toInt(),
      );

      // Get damaged quantity
      final damagedTransactions = await _getTransactionsByType(
        branchId: report.branchId,
        productId: item.productId,
        type: TransactionType.damage,
        startDate: startOfDay,
        endDate: endOfDay,
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

    return report.copyWith(items: refreshedItems);
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

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .where((t) => 
            (t.timestamp.isAfter(startDate) || t.timestamp.isAtSameMomentAs(startDate)) &&
            (t.timestamp.isBefore(endDate) || t.timestamp.isAtSameMomentAs(endDate))
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Reset filters
  void resetFilters() {
    fetchReports();
  }
}
