import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repositories/employee_repository.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_state.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _employeeRepository;

  EmployeeCubit(this._employeeRepository) : super(const EmployeeState());

  Future<void> loadEmployees() async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _employeeRepository.getEmployees();
      emit(state.copyWith(status: EmployeeStatus.success, employees: employees));
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل تحميل الموظفين'));
    }
  }

  Future<void> addEmployee(String username, String password, String branchId, List<String> permissions) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.addEmployee(username, password, branchId, permissions);
      await loadEmployees();
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل إضافة الموظف'));
    }
  }

  Future<void> deleteEmployee(String id) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.deleteEmployee(id);
      await loadEmployees();
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل حذف الموظف'));
    }
  }
}
