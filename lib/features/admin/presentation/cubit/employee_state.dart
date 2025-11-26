import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/user_model.dart';

enum EmployeeStatus { initial, loading, success, failure }

class EmployeeState extends Equatable {
  final EmployeeStatus status;
  final List<UserModel> employees;
  final String? errorMessage;

  const EmployeeState({
    this.status = EmployeeStatus.initial,
    this.employees = const [],
    this.errorMessage,
  });

  EmployeeState copyWith({
    EmployeeStatus? status,
    List<UserModel>? employees,
    String? errorMessage,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employees, errorMessage];
}
