import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/transaction_model.dart';

enum ReportStatus { initial, loading, success, failure }

class ReportState extends Equatable {
  final ReportStatus status;
  final List<TransactionModel> transactions;
  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  ReportState copyWith({
    ReportStatus? status,
    List<TransactionModel>? transactions,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}
