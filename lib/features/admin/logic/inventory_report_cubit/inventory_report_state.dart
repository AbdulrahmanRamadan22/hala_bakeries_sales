import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';

enum InventoryReportStatus { initial, loading, loaded, error }

class InventoryReportState extends Equatable {
  final InventoryReportStatus status;
  final List<InventoryCountModel> reports;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedBranchId;
  
  // Summary statistics
  final int totalCounts;
  final double totalExpectedValue;
  final double totalActualValue;
  final double netVarianceValue;

  const InventoryReportState({
    this.status = InventoryReportStatus.initial,
    this.reports = const [],
    this.errorMessage,
    this.startDate,
    this.endDate,
    this.selectedBranchId,
    this.totalCounts = 0,
    this.totalExpectedValue = 0.0,
    this.totalActualValue = 0.0,
    this.netVarianceValue = 0.0,
  });

  @override
  List<Object?> get props => [
        status,
        reports,
        errorMessage,
        startDate,
        endDate,
        selectedBranchId,
        totalCounts,
        totalExpectedValue,
        totalActualValue,
        netVarianceValue,
      ];

  InventoryReportState copyWith({
    InventoryReportStatus? status,
    List<InventoryCountModel>? reports,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedBranchId,
    int? totalCounts,
    double? totalExpectedValue,
    double? totalActualValue,
    double? netVarianceValue,
  }) {
    return InventoryReportState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      errorMessage: errorMessage ?? this.errorMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      totalCounts: totalCounts ?? this.totalCounts,
      totalExpectedValue: totalExpectedValue ?? this.totalExpectedValue,
      totalActualValue: totalActualValue ?? this.totalActualValue,
      netVarianceValue: netVarianceValue ?? this.netVarianceValue,
    );
  }
}
