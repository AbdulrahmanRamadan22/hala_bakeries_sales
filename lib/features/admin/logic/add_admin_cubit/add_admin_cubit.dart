import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';

part 'add_admin_state.dart';

class AddAdminCubit extends Cubit<AddAdminState> {
  final EmployeeRepository _employeeRepository;

  AddAdminCubit(this._employeeRepository) : super(const AddAdminState());

  Future<void> addAdmin({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    emit(state.copyWith(status: AddAdminStatus.loading));
    try {
      await _employeeRepository.addAdmin(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      emit(state.copyWith(status: AddAdminStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AddAdminStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void reset() {
    emit(const AddAdminState());
  }
}
