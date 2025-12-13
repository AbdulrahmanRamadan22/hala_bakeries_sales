part of 'admin_logs_cubit.dart';

enum AdminLogsStatus { initial, loading, success, failure }

class AdminLogsState extends Equatable {
  final AdminLogsStatus status;
  final List<TransactionModel> transactions;
  final List<UserModel> employees;
  final String? selectedEmployeeId;
  final Map<String, String> productNames; // ProductId -> ProductName
  final String? errorMessage;

  const AdminLogsState({
    this.status = AdminLogsStatus.initial,
    this.transactions = const [],
    this.employees = const [],
    this.selectedEmployeeId,
    this.productNames = const {},
    this.errorMessage,
  });

  AdminLogsState copyWith({
    AdminLogsStatus? status,
    List<TransactionModel>? transactions,
    List<UserModel>? employees,
    String? selectedEmployeeId,
    Map<String, String>? productNames,
    String? errorMessage,
  }) {
    return AdminLogsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      employees: employees ?? this.employees,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      productNames: productNames ?? this.productNames,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, employees, selectedEmployeeId, productNames, errorMessage];
}
