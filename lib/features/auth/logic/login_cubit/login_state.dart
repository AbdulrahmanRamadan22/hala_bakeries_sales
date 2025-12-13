import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

enum LoginStatus { initial, submitting, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isPasswordVisible;

  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.errorMessage,
    this.isPasswordVisible = false,
  });

  LoginState copyWith({
    LoginStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isPasswordVisible];
}
