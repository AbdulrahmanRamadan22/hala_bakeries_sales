import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/report_cubit/report_state.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/admin/logic/services/report_service.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';

class ReportCubit extends Cubit<ReportState> {
  final TransactionRepository _transactionRepository;
  final ProductRepository _productRepository;
  final EmployeeRepository _employeeRepository;
  final ReportService _reportService = ReportService();

  ReportCubit(
    this._transactionRepository,
    this._productRepository,
    this._employeeRepository,
  ) : super(const ReportState());

  Future<void> loadReports() async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final transactions = await _transactionRepository.getTransactions();
      final stats = _calculateStats(transactions);
      
      // Fetch product names
      final products = await _productRepository.getProducts();
      final productNames = {for (var p in products) p.id: p.name};

      // Fetch all user names (admins and employees)
      final users = await _employeeRepository.getAllUsers();
      final employeeNames = {for (var u in users) u.id: u.name};

      emit(state.copyWith(
        status: ReportStatus.success,
        transactions: transactions,
        stats: stats,
        productNames: productNames,
        employeeNames: employeeNames,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'فشل تحميل التقارير',
      ));
    }
  }

  ReportStats _calculateStats(List<TransactionModel> transactions) {
    double totalReceived = 0;
    double totalDamaged = 0;
    double totalSales = 0;

    for (var transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.receive:
          totalReceived += transaction.quantity;
          break;
        case TransactionType.damage:
          totalDamaged += transaction.quantity;
          break;
        case TransactionType.sale:
          totalSales += transaction.quantity;
          break;
        default:
          break;
      }
    }

    return ReportStats(
      totalReceived: totalReceived,
      totalDamaged: totalDamaged,
      totalSales: totalSales,
      transactionCount: transactions.length,
    );
  }

  Future<void> exportPdf() async {
    emit(state.copyWith(exportStatus: ExportStatus.exporting));
    try {
      final file = await _reportService.generatePdf(state.transactions);
      await Share.shareXFiles([XFile(file.path)], text: 'تقرير العمليات');
      emit(state.copyWith(exportStatus: ExportStatus.success));
    } catch (e) {
      emit(state.copyWith(exportStatus: ExportStatus.failure));
    }
  }

  Future<void> exportExcel() async {
    emit(state.copyWith(exportStatus: ExportStatus.exporting));
    try {
      final file = await _reportService.generateExcel(state.transactions);
      await Share.shareXFiles([XFile(file.path)], text: 'تقرير العمليات');
      emit(state.copyWith(exportStatus: ExportStatus.success));
    } catch (e) {
      emit(state.copyWith(exportStatus: ExportStatus.failure));
    }
  }
}
