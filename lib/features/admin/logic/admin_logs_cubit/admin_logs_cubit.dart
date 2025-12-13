import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';

part 'admin_logs_state.dart';

class AdminLogsCubit extends Cubit<AdminLogsState> {
  final TransactionRepository _transactionRepository;
  final EmployeeRepository _employeeRepository;
  final ProductRepository _productRepository;

  AdminLogsCubit(
    this._transactionRepository,
    this._employeeRepository,
    this._productRepository,
  ) : super(const AdminLogsState());

  Future<void> loadInitialData({String? employeeId}) async {
    emit(state.copyWith(status: AdminLogsStatus.loading, selectedEmployeeId: employeeId));
    try {
      final employees = await _employeeRepository.getEmployees();
      final List<TransactionModel> transactions;

      if (employeeId == null || employeeId.isEmpty) {
        transactions = await _transactionRepository.getTransactions();
      } else {
        transactions = await _transactionRepository.getTransactionsByEmployee(employeeId);
      }
      
      // Fetch product names
      final products = await _productRepository.getProducts();
      final productNames = {for (var p in products) p.id: p.name};
      
      emit(state.copyWith(
        status: AdminLogsStatus.success,
        transactions: transactions,
        employees: employees,
        selectedEmployeeId: employeeId,
        productNames: productNames,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminLogsStatus.failure,
        errorMessage: 'فشل تحميل سجل العمليات',
      ));
    }
  }

  Future<void> filterByEmployee(String? employeeId) async {
    emit(state.copyWith(
      status: AdminLogsStatus.loading,
      selectedEmployeeId: employeeId,
    ));
    
    try {
      final List<TransactionModel> transactions;
      
      if (employeeId == null || employeeId.isEmpty) {
        // Load all transactions
        transactions = await _transactionRepository.getTransactions();
      } else {
        // Load specific employee transactions
        transactions = await _transactionRepository.getTransactionsByEmployee(employeeId);
      }
      
      emit(state.copyWith(
        status: AdminLogsStatus.success,
        transactions: transactions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminLogsStatus.failure,
        errorMessage: 'فشل تحميل سجل العمليات',
      ));
    }
  }
}
