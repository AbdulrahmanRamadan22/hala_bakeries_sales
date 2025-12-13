import 'package:equatable/equatable.dart';

/// Model for individual product count item in inventory count
class InventoryCountItem extends Equatable {
  final String productId;
  final String productName;
  final String barcode;
  final double unitPrice;
  
  // Quantities
  final int openingBalance;      // Opening balance for the day
  final int receivedQuantity;    // Quantity received during the day
  final int damagedQuantity;     // Quantity damaged during the day
  final int expectedQuantity;    // Calculated: opening + received - damaged
  final int actualQuantity;      // Actual counted quantity
  
  // Calculated fields
  final int variance;            // Difference: expected - actual
  final double variancePercentage; // Variance as percentage
  final int calculatedSales;     // Calculated sales: expected - actual
  
  // Values
  final double expectedValue;    // Expected inventory value
  final double actualValue;      // Actual inventory value
  final double salesValue;       // Sales value
  
  final String? note;            // Optional note for this item

  const InventoryCountItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.unitPrice,
    required this.openingBalance,
    required this.receivedQuantity,
    required this.damagedQuantity,
    required this.expectedQuantity,
    required this.actualQuantity,
    required this.variance,
    required this.variancePercentage,
    required this.calculatedSales,
    required this.expectedValue,
    required this.actualValue,
    required this.salesValue,
    this.note,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        barcode,
        unitPrice,
        openingBalance,
        receivedQuantity,
        damagedQuantity,
        expectedQuantity,
        actualQuantity,
        variance,
        variancePercentage,
        calculatedSales,
        expectedValue,
        actualValue,
        salesValue,
        note,
      ];

  /// Factory constructor with automatic calculations
  factory InventoryCountItem.create({
    required String productId,
    required String productName,
    required String barcode,
    required double unitPrice,
    required int openingBalance,
    required int receivedQuantity,
    required int damagedQuantity,
    required int actualQuantity,
    String? note,
  }) {
    // Calculate expected quantity: opening + received - damaged
    final expectedQuantity = openingBalance + receivedQuantity - damagedQuantity;
    
    // Calculate variance: expected - actual
    final variance = expectedQuantity - actualQuantity;
    
    // Calculate variance percentage
    final variancePercentage = expectedQuantity > 0 
        ? (variance.abs() / expectedQuantity * 100).abs()
        : 0.0;
    
    // Calculate sales: expected - actual (same as variance but represents sales)
    final calculatedSales = variance;
    
    // Calculate values
    final expectedValue = expectedQuantity * unitPrice;
    final actualValue = actualQuantity * unitPrice;
    final salesValue = calculatedSales * unitPrice;
    
    return InventoryCountItem(
      productId: productId,
      productName: productName,
      barcode: barcode,
      unitPrice: unitPrice,
      openingBalance: openingBalance,
      receivedQuantity: receivedQuantity,
      damagedQuantity: damagedQuantity,
      expectedQuantity: expectedQuantity,
      actualQuantity: actualQuantity,
      variance: variance,
      variancePercentage: variancePercentage,
      calculatedSales: calculatedSales,
      expectedValue: expectedValue,
      actualValue: actualValue,
      salesValue: salesValue,
      note: note,
    );
  }

  factory InventoryCountItem.fromMap(Map<String, dynamic> map) {
    return InventoryCountItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      barcode: map['barcode'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      openingBalance: map['openingBalance'] ?? 0,
      receivedQuantity: map['receivedQuantity'] ?? 0,
      damagedQuantity: map['damagedQuantity'] ?? 0,
      expectedQuantity: map['expectedQuantity'] ?? 0,
      actualQuantity: map['actualQuantity'] ?? 0,
      variance: map['variance'] ?? 0,
      variancePercentage: (map['variancePercentage'] ?? 0).toDouble(),
      calculatedSales: map['calculatedSales'] ?? 0,
      expectedValue: (map['expectedValue'] ?? 0).toDouble(),
      actualValue: (map['actualValue'] ?? 0).toDouble(),
      salesValue: (map['salesValue'] ?? 0).toDouble(),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'unitPrice': unitPrice,
      'openingBalance': openingBalance,
      'receivedQuantity': receivedQuantity,
      'damagedQuantity': damagedQuantity,
      'expectedQuantity': expectedQuantity,
      'actualQuantity': actualQuantity,
      'variance': variance,
      'variancePercentage': variancePercentage,
      'calculatedSales': calculatedSales,
      'expectedValue': expectedValue,
      'actualValue': actualValue,
      'salesValue': salesValue,
      'note': note,
    };
  }

  /// Copy with method for updating actual quantity
  InventoryCountItem copyWith({
    int? actualQuantity,
    String? note,
  }) {
    return InventoryCountItem.create(
      productId: productId,
      productName: productName,
      barcode: barcode,
      unitPrice: unitPrice,
      openingBalance: openingBalance,
      receivedQuantity: receivedQuantity,
      damagedQuantity: damagedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      note: note ?? this.note,
    );
  }

  /// Get variance color based on percentage
  /// Green: < 5%, Yellow: 5-15%, Red: > 15%
  String getVarianceLevel() {
    if (variancePercentage < 5) return 'green';
    if (variancePercentage < 15) return 'yellow';
    return 'red';
  }
}
