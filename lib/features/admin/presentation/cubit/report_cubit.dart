import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/report_state.dart';
import 'package:hala_bakeries_sales/features/shared/data/repositories/transaction_repository.dart';

class ReportCubit extends Cubit<ReportState> {
  final TransactionRepository _transactionRepository;

  ReportCubit(this._transactionRepository) : super(const ReportState());

  Future<void> loadReports() async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final transactions = await _transactionRepository.getTransactions();
      emit(state.copyWith(status: ReportStatus.success, transactions: transactions));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: 'فشل تحميل التقارير'));
    }
  }
}
