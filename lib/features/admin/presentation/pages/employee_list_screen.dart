import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_state.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/employees/add'),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<EmployeeCubit, EmployeeState>(
        builder: (context, state) {
          if (state.status == EmployeeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.employees.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد موظفين حالياً',
                style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.employees.length,
            itemBuilder: (context, index) {
              final employee = state.employees[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.info),
                  ),
                  title: Text(employee.username, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'الفرع: ${employee.branchId ?? "غير محدد"}', // In real app, map ID to Name
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف الموظف'),
                          content: Text('هل أنت متأكد من حذف ${employee.username}؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<EmployeeCubit>().deleteEmployee(employee.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('حذف', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
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
