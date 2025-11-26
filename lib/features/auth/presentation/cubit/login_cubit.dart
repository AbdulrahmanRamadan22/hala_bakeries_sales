import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/auth/data/repositories/auth_repository.dart';
import 'package:hala_bakeries_sales/features/auth/presentation/cubit/login_state.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/user_model.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit(this._authRepository) : super(const LoginState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'الرجاء إدخال اسم المستخدم وكلمة المرور',
      ));
      return;
    }

    emit(state.copyWith(status: LoginStatus.submitting));

    try {
      // Appending a dummy domain if not present, assuming username input
      final email = username.contains('@') ? username : '$username@halabakeries.com';
      
      final user = await _authRepository.login(email, password);
      
      emit(state.copyWith(
        status: LoginStatus.success,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'فشل تسجيل الدخول: ${e.toString().replaceAll("Exception:", "")}',
      ));
    }
  }
}
