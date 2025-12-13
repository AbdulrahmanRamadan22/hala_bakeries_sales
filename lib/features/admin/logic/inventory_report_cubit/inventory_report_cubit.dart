import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_report_cubit/inventory_report_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/inventory_count_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';

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

  /// Reset filters
  void resetFilters() {
    fetchReports();
  }
}
