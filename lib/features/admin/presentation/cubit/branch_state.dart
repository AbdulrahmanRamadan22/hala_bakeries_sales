import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/branch_model.dart';

enum BranchStatus { initial, loading, success, failure }

class BranchState extends Equatable {
  final BranchStatus status;
  final List<BranchModel> branches;
  final String? errorMessage;

  const BranchState({
    this.status = BranchStatus.initial,
    this.branches = const [],
    this.errorMessage,
  });

  BranchState copyWith({
    BranchStatus? status,
    List<BranchModel>? branches,
    String? errorMessage,
  }) {
    return BranchState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, branches, errorMessage];
}
