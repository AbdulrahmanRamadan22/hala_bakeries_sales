import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/report_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/report_state.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/transaction_model.dart';
import 'package:intl/intl.dart' as intl;

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والسجلات'),
      ),
      body: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          if (state.status == ReportStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.transactions.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد سجلات حالياً',
                style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.transactions.length,
            itemBuilder: (context, index) {
              final transaction = state.transactions[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForType(transaction.type).withOpacity(0.1),
                    child: Icon(_getIconForType(transaction.type), color: _getColorForType(transaction.type)),
                  ),
                  title: Text(
                    _getTextForType(transaction.type),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المنتج: ${transaction.productId} | الكمية: ${transaction.quantity}', style: GoogleFonts.cairo()),
                      Text(
                        'التاريخ: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(transaction.timestamp)}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      if (transaction.notes.isNotEmpty)
                        Text('ملاحظات: ${transaction.notes}', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.error)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('قبل: ${transaction.beforeStock}', style: const TextStyle(fontSize: 10)),
                      const Icon(Icons.arrow_downward, size: 12),
                      Text('بعد: ${transaction.afterStock}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForType(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return AppColors.success;
      case TransactionType.damage:
        return AppColors.warning;
      case TransactionType.spoilage:
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return Icons.add_shopping_cart;
      case TransactionType.damage:
        return Icons.broken_image;
      case TransactionType.spoilage:
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getTextForType(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return 'استلام بضاعة';
      case TransactionType.damage:
        return 'تسجيل تالف';
      case TransactionType.spoilage:
        return 'تسجيل هالك';
      default:
        return 'عملية أخرى';
    }
  }
}
