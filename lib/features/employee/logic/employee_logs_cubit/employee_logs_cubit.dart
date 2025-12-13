import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';

import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';

part 'employee_logs_state.dart';

class EmployeeLogsCubit extends Cubit<EmployeeLogsState> {
  final TransactionRepository _transactionRepository;
  final ProductRepository _productRepository;

  EmployeeLogsCubit(this._transactionRepository, this._productRepository) : super(const EmployeeLogsState());

  Future<void> loadMyTransactions() async {
    emit(state.copyWith(status: EmployeeLogsStatus.loading));
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        emit(state.copyWith(
          status: EmployeeLogsStatus.failure,
          errorMessage: 'لم يتم تسجيل الدخول',
        ));
        return;
      }

      final transactions = await _transactionRepository.getTransactionsByEmployee(currentUserId);
      print('Loaded ${transactions.length} transactions for user $currentUserId');
      
      // Fetch all products to get names
      // Optimization: In a real app with many products, we might want to fetch only relevant products
      // or cache them. For now, fetching all is fine.
      final products = await _productRepository.getProducts();
      final productNames = {for (var p in products) p.id: p.name};

      emit(state.copyWith(
        status: EmployeeLogsStatus.success,
        transactions: transactions,
        productNames: productNames,
      ));
    } catch (e) {
      print('Error loading transactions: $e');
      emit(state.copyWith(
        status: EmployeeLogsStatus.failure,
        errorMessage: 'فشل تحميل سجل العمليات: ${e.toString()}',
      ));
    }
  }
}
