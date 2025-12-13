import 'package:equatable/equatable.dart';

enum TransactionType { receive, damage, adjustment, sale, openingBalance }

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final String branchId;
  final String productId;
  final String userId; // Employee who performed the action
  final double quantity;
  final DateTime timestamp;
  final String notes;
  final double beforeStock;
  final double afterStock;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.branchId,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.timestamp,
    this.notes = '',
    required this.beforeStock,
    required this.afterStock,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        branchId,
        productId,
        userId,
        quantity,
        timestamp,
        notes,
        beforeStock,
        afterStock,
      ];

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    String? branchId,
    String? productId,
    String? userId,
    double? quantity,
    DateTime? timestamp,
    String? notes,
    double? beforeStock,
    double? afterStock,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      beforeStock: beforeStock ?? this.beforeStock,
      afterStock: afterStock ?? this.afterStock,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'branchId': branchId,
      'productId': productId,
      'userId': userId,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'beforeStock': beforeStock,
      'afterStock': afterStock,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.adjustment,
      ),
      branchId: map['branchId'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
      beforeStock: (map['beforeStock'] ?? 0.0).toDouble(),
      afterStock: (map['afterStock'] ?? 0.0).toDouble(),
    );
  }
}
