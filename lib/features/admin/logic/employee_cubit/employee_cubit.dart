import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_state.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _employeeRepository;

  EmployeeCubit(this._employeeRepository) : super(const EmployeeState());

  Future<void> loadEmployees({bool forceRefresh = false}) async {
    if (!forceRefresh && state.employees.isNotEmpty) {
      return;
    }
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _employeeRepository.getEmployees();
      emit(state.copyWith(status: EmployeeStatus.success, employees: employees));
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل تحميل الموظفين'));
    }
  }

  Future<void> addEmployee({
    required String name,
    required String email,
    required String password,
    required String branchId,
    required List<String> permissions,
  }) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.addEmployee(
        name: name,
        email: email,
        password: password,
        phone: "", // Optional, can be added later
        branchId: branchId,
      );
      await loadEmployees(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> updateEmployee({
    required String id,
    required String branchId,
    required List<String> permissions,
  }) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.updateEmployee(
        id: id,
        branchId: branchId,
        permissions: permissions,
      );
      await loadEmployees(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل تحديث بيانات الموظف'));
    }
  }

  Future<void> updateEmployeeName({
    required String id,
    required String name,
  }) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.updateEmployeeName(id: id, name: name);
      await loadEmployees(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل تحديث اسم الموظف'));
    }
  }

  Future<void> resetEmployeePassword(String email) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.updateEmployeePassword(email: email);
      emit(state.copyWith(status: EmployeeStatus.success)); // Or a specific status for toast
      // Reloading isn't strictly necessary but good for consistency
      await loadEmployees(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل إرسال بريد إعادة تعيين كلمة المرور'));
    }
  }

  Future<void> deleteEmployee(String id) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      await _employeeRepository.deleteEmployee(id);
      await loadEmployees(forceRefresh: true);
    } catch (e) {
      emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: 'فشل حذف الموظف'));
    }
  }
}
