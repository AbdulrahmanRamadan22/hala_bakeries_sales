import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final AuthRepository _authRepository;

  ChangePasswordCubit(this._authRepository) : super(const ChangePasswordState());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(status: ChangePasswordStatus.loading));
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(status: ChangePasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void reset() {
    emit(const ChangePasswordState());
  }
}
