part of 'add_admin_cubit.dart';

enum AddAdminStatus { initial, loading, success, failure }

class AddAdminState extends Equatable {
  final AddAdminStatus status;
  final String? errorMessage;

  const AddAdminState({
    this.status = AddAdminStatus.initial,
    this.errorMessage,
  });

  AddAdminState copyWith({
    AddAdminStatus? status,
    String? errorMessage,
  }) {
    return AddAdminState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
