import 'package:equatable/equatable.dart';

enum LowStockStatus { initial, loading, success, failure }

class LowStockItem {
  final String productId;
  final String productName;
  final String category;
  final int minStockLevel;
  final List<BranchStockInfo> branchStocks;
  final int totalStock;

  LowStockItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.minStockLevel,
    required this.branchStocks,
    required this.totalStock,
  });
}

class BranchStockInfo {
  final String branchId;
  final String branchName;
  final int currentStock;
  final bool isLow;

  BranchStockInfo({
    required this.branchId,
    required this.branchName,
    required this.currentStock,
    required this.isLow,
  });
}

class LowStockState extends Equatable {
  final LowStockStatus status;
  final List<LowStockItem> lowStockItems;
  final String? errorMessage;

  const LowStockState({
    this.status = LowStockStatus.initial,
    this.lowStockItems = const [],
    this.errorMessage,
  });

  LowStockState copyWith({
    LowStockStatus? status,
    List<LowStockItem>? lowStockItems,
    String? errorMessage,
  }) {
    return LowStockState(
      status: status ?? this.status,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, lowStockItems, errorMessage];
}
