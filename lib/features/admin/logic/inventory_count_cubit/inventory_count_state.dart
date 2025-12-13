import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_item_model.dart';

enum InventoryCountStatus {
  initial,
  loading,
  loaded,
  saving,
  success,
  error,
}

class InventoryCountState extends Equatable {
  final InventoryCountStatus status;
  final InventoryCountModel? currentCount;
  final List<InventoryCountItem> items;
  final List<InventoryCountModel> historicalCounts;
  final String? errorMessage;
  final bool canEdit;
  final bool isWithinTimeWindow;

  const InventoryCountState({
    this.status = InventoryCountStatus.initial,
    this.currentCount,
    this.items = const [],
    this.historicalCounts = const [],
    this.errorMessage,
    this.canEdit = false,
    this.isWithinTimeWindow = false,
  });

  @override
  List<Object?> get props => [
        status,
        currentCount,
        items,
        historicalCounts,
        errorMessage,
        canEdit,
        isWithinTimeWindow,
      ];

  InventoryCountState copyWith({
    InventoryCountStatus? status,
    InventoryCountModel? currentCount,
    List<InventoryCountItem>? items,
    List<InventoryCountModel>? historicalCounts,
    String? errorMessage,
    bool? canEdit,
    bool? isWithinTimeWindow,
  }) {
    return InventoryCountState(
      status: status ?? this.status,
      currentCount: currentCount ?? this.currentCount,
      items: items ?? this.items,
      historicalCounts: historicalCounts ?? this.historicalCounts,
      errorMessage: errorMessage,
      canEdit: canEdit ?? this.canEdit,
      isWithinTimeWindow: isWithinTimeWindow ?? this.isWithinTimeWindow,
    );
  }
}

