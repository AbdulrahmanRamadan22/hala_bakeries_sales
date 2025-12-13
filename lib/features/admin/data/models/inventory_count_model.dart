import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_item_model.dart';

/// Model for daily inventory count
class InventoryCountModel extends Equatable {
  final String id;
  final DateTime date;
  final String branchId;
  final String branchName;
  final String employeeId;
  final String employeeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InventoryCountItem> items;
  final double totalExpectedValue;
  final double totalActualValue;
  final double totalSalesValue;
  final String? notes;
  final String status; // 'draft' or 'completed'

  const InventoryCountModel({
    required this.id,
    required this.date,
    required this.branchId,
    required this.branchName,
    required this.employeeId,
    required this.employeeName,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.totalExpectedValue,
    required this.totalActualValue,
    required this.totalSalesValue,
    this.notes,
    this.status = 'draft',
  });

  @override
  List<Object?> get props => [
        id,
        date,
        branchId,
        branchName,
        employeeId,
        employeeName,
        createdAt,
        updatedAt,
        items,
        totalExpectedValue,
        totalActualValue,
        totalSalesValue,
        notes,
        status,
      ];

  /// Calculate totals from items
  factory InventoryCountModel.create({
    required String id,
    required DateTime date,
    required String branchId,
    required String branchName,
    required String employeeId,
    required String employeeName,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<InventoryCountItem> items,
    String? notes,
    String status = 'draft',
  }) {
    double totalExpected = 0;
    double totalActual = 0;
    double totalSales = 0;

    for (var item in items) {
      totalExpected += item.expectedValue;
      totalActual += item.actualValue;
      totalSales += item.salesValue;
    }

    return InventoryCountModel(
      id: id,
      date: date,
      branchId: branchId,
      branchName: branchName,
      employeeId: employeeId,
      employeeName: employeeName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items,
      totalExpectedValue: totalExpected,
      totalActualValue: totalActual,
      totalSalesValue: totalSales,
      notes: notes,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'branchId': branchId,
      'branchName': branchName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'items': items.map((item) => item.toMap()).toList(),
      'totalExpectedValue': totalExpectedValue,
      'totalActualValue': totalActualValue,
      'totalSalesValue': totalSalesValue,
      'notes': notes,
      'status': status,
    };
  }

  factory InventoryCountModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryCountModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => InventoryCountItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalExpectedValue: (map['totalExpectedValue'] ?? 0).toDouble(),
      totalActualValue: (map['totalActualValue'] ?? 0).toDouble(),
      totalSalesValue: (map['totalSalesValue'] ?? 0).toDouble(),
      notes: map['notes'],
      status: map['status'] ?? 'draft',
    );
  }

  /// Copy with method
  InventoryCountModel copyWith({
    List<InventoryCountItem>? items,
    String? notes,
    String? status,
    DateTime? updatedAt,
  }) {
    return InventoryCountModel.create(
      id: id,
      date: date,
      branchId: branchId,
      branchName: branchName,
      employeeId: employeeId,
      employeeName: employeeName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  /// Check if count can be edited (within 1 hour of creation)
  bool canBeEditedByEmployee() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 1;
  }

  /// Get count of items with high variance (> 15%)
  int getHighVarianceCount() {
    return items.where((item) => item.variancePercentage > 15).length;
  }

  /// Get count of items with medium variance (5-15%)
  int getMediumVarianceCount() {
    return items.where((item) => item.variancePercentage >= 5 && item.variancePercentage <= 15).length;
  }

  /// Get count of items with low variance (< 5%)
  int getLowVarianceCount() {
    return items.where((item) => item.variancePercentage < 5).length;
  }
}
