part of 'employee_logs_cubit.dart';

enum EmployeeLogsStatus { initial, loading, success, failure }

class EmployeeLogsState extends Equatable {
  final EmployeeLogsStatus status;
  final List<TransactionModel> transactions;
  final Map<String, String> productNames; // ProductId -> ProductName
  final String? errorMessage;

  const EmployeeLogsState({
    this.status = EmployeeLogsStatus.initial,
    this.transactions = const [],
    this.productNames = const {},
    this.errorMessage,
  });

  EmployeeLogsState copyWith({
    EmployeeLogsStatus? status,
    List<TransactionModel>? transactions,
    Map<String, String>? productNames,
    String? errorMessage,
  }) {
    return EmployeeLogsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      productNames: productNames ?? this.productNames,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, productNames, errorMessage];
}
