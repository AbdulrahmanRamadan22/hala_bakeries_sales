import 'package:equatable/equatable.dart';

class BranchStockModel extends Equatable {
  final String id; // branchId_productId
  final String branchId;
  final String productId;
  final int currentStock;
  final bool hasOpeningBalance;
  final DateTime lastUpdated;

  const BranchStockModel({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.currentStock,
    this.hasOpeningBalance = false,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        branchId,
        productId,
        currentStock,
        hasOpeningBalance,
        lastUpdated,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchId': branchId,
      'productId': productId,
      'currentStock': currentStock,
      'hasOpeningBalance': hasOpeningBalance,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BranchStockModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchStockModel(
      id: id,
      branchId: map['branchId'] ?? '',
      productId: map['productId'] ?? '',
      currentStock: (map['currentStock'] as num? ?? 0).toInt(),
      hasOpeningBalance: map['hasOpeningBalance'] ?? false,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }

  BranchStockModel copyWith({
    String? id,
    String? branchId,
    String? productId,
    int? currentStock,
    bool? hasOpeningBalance,
    DateTime? lastUpdated,
  }) {
    return BranchStockModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      currentStock: currentStock ?? this.currentStock,
      hasOpeningBalance: hasOpeningBalance ?? this.hasOpeningBalance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static String generateId(String branchId, String productId) {
    return '${branchId}_$productId';
  }
}
