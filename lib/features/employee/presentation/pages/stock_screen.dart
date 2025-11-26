import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/stock_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/stock_state.dart';
import 'package:intl/intl.dart' as intl;

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون الحالي'),
      ),
      body: BlocBuilder<StockCubit, StockState>(
        builder: (context, state) {
          if (state.status == StockStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.stockItems.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد بيانات مخزون',
                style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.stockItems.length,
            itemBuilder: (context, index) {
              final item = state.stockItems[index];
              final isLowStock = item.quantity < 10; // Threshold example

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.product.name,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowStock ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.quantity} ${item.product.unit}',
                              style: GoogleFonts.cairo(
                                color: isLowStock ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الرصيد الافتتاحي: ${item.openingBalance}',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            'آخر تحديث: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(item.lastUpdated)}',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
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
}
