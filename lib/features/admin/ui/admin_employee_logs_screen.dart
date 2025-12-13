import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/admin_logs_cubit/admin_logs_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';

class AdminEmployeeLogsScreen extends StatelessWidget {
  final String? employeeId;
  
  const AdminEmployeeLogsScreen({super.key, this.employeeId});

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
        return AppColors.primaryGreen;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return Icons.add_shopping_cart;
      case TransactionType.damage:
        return Icons.broken_image;
      case TransactionType.sale:
        return Icons.shopping_cart;
      case TransactionType.adjustment:
        return Icons.edit;
      case TransactionType.openingBalance:
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل عمليات الموظفين'),
        elevation: 0,
      ),
      body: BlocBuilder<AdminLogsCubit, AdminLogsState>(
        builder: (context, state) {
          if (state.status == AdminLogsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == AdminLogsStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'حدث خطأ',
                    style: GoogleFonts.cairo(color: AppColors.error),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Modern Filter Dropdown
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: state.selectedEmployeeId,
                    decoration: InputDecoration(
                      labelText: 'فلتر حسب الموظف',
                      labelStyle: GoogleFonts.cairo(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: AppColors.primaryGreen,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'جميع الموظفين',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      ...state.employees.map((employee) {
                        return DropdownMenuItem(
                          value: employee.id,
                          child: Text(
                            employee.name,
                            style: GoogleFonts.cairo(),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      context.read<AdminLogsCubit>().filterByEmployee(value);
                    },
                  ),
                ),
              ),
              
              // Transactions List
              Expanded(
                child: state.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history,
                                size: 64,
                                color: AppColors.info.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'لا توجد عمليات',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لم يتم تسجيل أي عمليات بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = state.transactions[index];
                          final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
                          final timeFormat = DateFormat('hh:mm a', 'ar');
                          
                          final employee = state.employees
                              .where((e) => e.id == transaction.userId)
                              .firstOrNull;
                          
                          final employeeName = employee?.name ?? 'موظف غير موجود';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              border: Border.all(
                                color: _getTransactionColor(transaction.type).withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getTransactionColor(transaction.type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getTransactionColor(transaction.type).withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          _getTransactionIcon(transaction.type),
                                          color: _getTransactionColor(transaction.type),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getTransactionTypeArabic(transaction.type),
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              state.productNames[transaction.productId] ?? 'منتج غير معروف',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: AppColors.primaryGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getTransactionColor(transaction.type).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          transaction.type == TransactionType.receive 
                                              ? '+${transaction.quantity.toStringAsFixed(0)}' 
                                              : '-${transaction.quantity.toStringAsFixed(0)}',
                                          style: GoogleFonts.cairo(
                                            color: _getTransactionColor(transaction.type),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 12,
                                          color: AppColors.info,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          employeeName,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${dateFormat.format(transaction.timestamp)} - ${timeFormat.format(transaction.timestamp)}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (transaction.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.note_outlined,
                                            size: 14,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              transaction.notes,
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: AppColors.warning,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
