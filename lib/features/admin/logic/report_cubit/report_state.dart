import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';

enum ReportStatus { initial, loading, success, failure }
enum ExportStatus { idle, exporting, success, failure }

class ReportStats {
  final double totalReceived;
  final double totalDamaged;
  final double totalSales;
  final int transactionCount;

  const ReportStats({
    this.totalReceived = 0,
    this.totalDamaged = 0,
    this.totalSales = 0,
    this.transactionCount = 0,
  });
}

class ReportState extends Equatable {
  final ReportStatus status;
  final List<TransactionModel> transactions;
  final String? errorMessage;
  final ReportStats stats;
  final ExportStatus exportStatus;
  final Map<String, String> productNames; // ProductId -> ProductName
  final Map<String, String> employeeNames; // UserId -> UserName

  const ReportState({
    this.status = ReportStatus.initial,
    this.transactions = const [],
    this.errorMessage,
    this.stats = const ReportStats(),
    this.exportStatus = ExportStatus.idle,
    this.productNames = const {},
    this.employeeNames = const {},
  });

  ReportState copyWith({
    ReportStatus? status,
    List<TransactionModel>? transactions,
    String? errorMessage,
    ReportStats? stats,
    ExportStatus? exportStatus,
    Map<String, String>? productNames,
    Map<String, String>? employeeNames,
  }) {
    return ReportState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
      stats: stats ?? this.stats,
      exportStatus: exportStatus ?? this.exportStatus,
      productNames: productNames ?? this.productNames,
      employeeNames: employeeNames ?? this.employeeNames,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage, stats, exportStatus, productNames, employeeNames];
}
