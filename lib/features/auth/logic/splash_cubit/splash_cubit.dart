import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/features/auth/logic/splash_cubit/splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _authRepository;

  SplashCubit(this._authRepository) : super(const SplashState());

  Future<void> checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(SplashState(status: SplashStatus.authenticated, user: user));
      } else {
        emit(const SplashState(status: SplashStatus.unauthenticated));
      }
    } catch (e) {
      emit(const SplashState(status: SplashStatus.unauthenticated));
    }
  }
}
