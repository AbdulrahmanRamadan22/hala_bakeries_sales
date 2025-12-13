import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';
import 'package:uuid/uuid.dart';

class BranchCubit extends Cubit<BranchState> {
  final BranchRepository _branchRepository;

  BranchCubit(this._branchRepository) : super(const BranchState());

  Future<void> loadBranches() async {
    emit(state.copyWith(status: BranchStatus.loading));
    try {
      final branches = await _branchRepository.getBranches();
      emit(state.copyWith(status: BranchStatus.success, branches: branches));
    } catch (e) {
      emit(state.copyWith(status: BranchStatus.failure, errorMessage: 'فشل تحميل الفروع'));
    }
  }

  Future<void> addBranch(String name, String location) async {
    emit(state.copyWith(status: BranchStatus.loading));
    try {
      final newBranch = BranchModel(
        id: const Uuid().v4(),
        name: name,
        location: location,
        createdAt: DateTime.now(),
      );
      await _branchRepository.addBranch(newBranch);
      
      // Reload branches to get fresh list
      await loadBranches();
    } catch (e) {
      emit(state.copyWith(status: BranchStatus.failure, errorMessage: 'فشل إضافة الفرع'));
    }
  }

  Future<void> updateBranch(BranchModel branch) async {
    emit(state.copyWith(status: BranchStatus.loading));
    try {
      await _branchRepository.updateBranch(branch);
      await loadBranches();
    } catch (e) {
      emit(state.copyWith(status: BranchStatus.failure, errorMessage: 'فشل تحديث الفرع'));
    }
  }

  Future<void> deleteBranch(String id) async {
    emit(state.copyWith(status: BranchStatus.loading));
    try {
      await _branchRepository.deleteBranch(id);
      await loadBranches();
    } catch (e) {
      emit(state.copyWith(status: BranchStatus.failure, errorMessage: 'فشل حذف الفرع'));
    }
  }
}
