import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/branch_state.dart';

class BranchListScreen extends StatelessWidget {
  const BranchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفروع'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/branches/add'),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<BranchCubit, BranchState>(
        builder: (context, state) {
          if (state.status == BranchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.branches.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد فروع حالياً',
                style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.branches.length,
            itemBuilder: (context, index) {
              final branch = state.branches[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.store, color: AppColors.primaryGreen),
                  ),
                  title: Text(branch.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text(branch.location, style: GoogleFonts.cairo()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      // Confirm dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف الفرع'),
                          content: Text('هل أنت متأكد من حذف ${branch.name}؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<BranchCubit>().deleteBranch(branch.id);
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
