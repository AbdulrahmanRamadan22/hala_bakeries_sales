import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/employee/logic/employee_logs_cubit/employee_logs_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';

class EmployeeLogsScreen extends StatelessWidget {
  const EmployeeLogsScreen({super.key});

  String _getTransactionTypeArabic(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return 'استلام بضاعة';
      case TransactionType.damage:
        return 'تالف';
      case TransactionType.sale:
        return 'بيع';
      case TransactionType.adjustment:
        return 'تعديل';
      case TransactionType.openingBalance:
        return 'رصيد افتتاحي';
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return AppColors.success;
      case TransactionType.damage:
        return AppColors.error;
      case TransactionType.sale:
        return AppColors.info;
      case TransactionType.adjustment:
        return AppColors.warning;
      case TransactionType.openingBalance:
        return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل عملياتي',
          style: GoogleFonts.cairo(),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<EmployeeLogsCubit, EmployeeLogsState>(
        builder: (context, state) {
          if (state.status == EmployeeLogsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == EmployeeLogsStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'حدث خطأ',
                    style: GoogleFonts.cairo(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EmployeeLogsCubit>().loadMyTransactions();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          } else if (state.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد عمليات حتى الآن',
                    style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.transactions.length,
            itemBuilder: (context, index) {
              final transaction = state.transactions[index];
              final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
              final timeFormat = DateFormat('hh:mm a', 'ar');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTransactionColor(transaction.type).withOpacity(0.1),
                    child: Icon(
                      transaction.type == TransactionType.receive
                          ? Icons.add_shopping_cart
                          : Icons.remove_shopping_cart,
                      color: _getTransactionColor(transaction.type),
                    ),
                  ),
                  title: Text(
                    _getTransactionTypeArabic(transaction.type),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'المنتج: ',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: state.productNames[transaction.productId] ?? 'منتج غير معروف',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'الكمية: ${transaction.quantity.toStringAsFixed(0)}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      Text(
                        '${dateFormat.format(transaction.timestamp)} - ${timeFormat.format(transaction.timestamp)}',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (transaction.notes.isNotEmpty)
                        Text(
                          'ملاحظات: ${transaction.notes}',
                          style: GoogleFonts.cairo(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTransactionColor(transaction.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.type == TransactionType.receive ? '+${transaction.quantity.toStringAsFixed(0)}' : '-${transaction.quantity.toStringAsFixed(0)}',
                      style: GoogleFonts.cairo(
                        color: _getTransactionColor(transaction.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
