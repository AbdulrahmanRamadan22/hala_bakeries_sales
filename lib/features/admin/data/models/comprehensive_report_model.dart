import 'package:equatable/equatable.dart';

/// Comprehensive report model that aggregates inventory, sales, and damage data
class ComprehensiveReportModel extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? branchId;
  final String? branchName;
  
  // Summary totals - quantities
  final int totalInventoryCount;
  final int totalSalesCount;
  final int totalDamageCount;
  
  // Summary totals - values in SAR
  final double totalInventoryValue;
  final double totalSalesValue;
  final double totalDamageValue;
  
  // Detailed data
  final List<ProductReportItem> products;
  final List<OperationReportItem> operations;

  const ComprehensiveReportModel({
    required this.startDate,
    required this.endDate,
    this.branchId,
    this.branchName,
    required this.totalInventoryCount,
    required this.totalSalesCount,
    required this.totalDamageCount,
    required this.totalInventoryValue,
    required this.totalSalesValue,
    required this.totalDamageValue,
    required this.products,
    required this.operations,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        branchId,
        branchName,
        totalInventoryCount,
        totalSalesCount,
        totalDamageCount,
        totalInventoryValue,
        totalSalesValue,
        totalDamageValue,
        products,
        operations,
      ];
}

/// Product-level report item with inventory, sales, and damage details
class ProductReportItem extends Equatable {
  final String productId;
  final String productName;
  final String barcode;
  final String branchName;
  final double unitPrice;
  
  // Current stock
  final int currentStock;
  final double currentStockValue;
  
  // Sales data
  final int salesCount;
  final double salesValue;
  
  // Damage data
  final int damageCount;
  final double damageValue;

  const ProductReportItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.branchName,
    required this.unitPrice,
    required this.currentStock,
    required this.currentStockValue,
    required this.salesCount,
    required this.salesValue,
    required this.damageCount,
    required this.damageValue,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        barcode,
        branchName,
        unitPrice,
        currentStock,
        currentStockValue,
        salesCount,
        salesValue,
        damageCount,
        damageValue,
      ];
}

/// Operation/Transaction report item
class OperationReportItem extends Equatable {
  final String id;
  final DateTime date;
  final String employeeName;
  final String operationType; // 'جرد', 'مبيعات', 'تالف', 'وارد'
  final String details;
  final String? branchName;

  const OperationReportItem({
    required this.id,
    required this.date,
    required this.employeeName,
    required this.operationType,
    required this.details,
    this.branchName,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        employeeName,
        operationType,
        details,
        branchName,
      ];
}
