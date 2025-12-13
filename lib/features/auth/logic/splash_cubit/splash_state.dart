import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

enum SplashStatus { initial, loading, authenticated, unauthenticated }

class SplashState extends Equatable {
  final SplashStatus status;
  final UserModel? user;

  const SplashState({
    this.status = SplashStatus.initial,
    this.user,
  });

  @override
  List<Object?> get props => [status, user];
}
