import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_state.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/core/permissions/permission_service.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        elevation: 0,
      ),
      floatingActionButton: FutureBuilder(
        future: getIt<AuthRepository>().getCurrentUser(),
        builder: (context, snapshot) {
          final canEdit = snapshot.hasData && 
                          PermissionService.canEditAdminFeatures(snapshot.data!);
          
          if (!canEdit) {
            return const SizedBox.shrink();
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/admin/employees/add');
                if (mounted) {
                  context.read<EmployeeCubit>().loadEmployees();
                }
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة موظف',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      body: BlocBuilder<EmployeeCubit, EmployeeState>(
        builder: (context, state) {
          if (state.status == EmployeeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.employees.isEmpty) {
            return Center(
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
                      Icons.people_outline,
                      size: 64,
                      color: AppColors.info.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'لا يوجد موظفين حالياً',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بإضافة موظف جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocBuilder<BranchCubit, BranchState>(
            builder: (context, branchState) {
              return FutureBuilder(
                future: getIt<AuthRepository>().getCurrentUser(),
                builder: (context, snapshot) {
                  final canEdit = snapshot.hasData && 
                                  PermissionService.canEditAdminFeatures(snapshot.data!);

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.employees.length,
                    itemBuilder: (context, index) {
                      final employee = state.employees[index];
                      final branch = branchState.branches
                          .where((b) => b.id == employee.branchId)
                          .firstOrNull;
                      final branchDisplay = branch?.name ?? "غير محدد";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.15),
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
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: canEdit ? () async {
                              await context.push('/admin/employees/edit',
                                  extra: employee);
                              if (mounted) {
                                context.read<EmployeeCubit>().loadEmployees();
                              }
                            } : null,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: AppColors.info.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.info.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.info,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.name,
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                employee.email,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.primaryGreen
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.store,
                                                size: 12,
                                                color: AppColors.primaryGreen,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                branchDisplay,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: AppColors.primaryGreen,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.history,
                                        color: AppColors.info,
                                        size: 22,
                                      ),
                                      tooltip: 'سجل العمليات',
                                      onPressed: () {
                                        context.push('/admin/employee-logs',
                                            extra: employee.id);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (canEdit) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.lock_reset,
                                          color: AppColors.warning,
                                          size: 22,
                                        ),
                                        tooltip: 'إعادة تعيين كلمة المرور',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Text(
                                                'إعادة تعيين كلمة المرور',
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'سيتم إرسال بريد إلكتروني إلى ${employee.email} لإعادة تعيين كلمة المرور. هل تريد المتابعة؟',
                                                style: GoogleFonts.cairo(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: Text(
                                                    'إلغاء',
                                                    style: GoogleFonts.cairo(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    try {
                                                      await context
                                                          .read<EmployeeCubit>()
                                                          .resetEmployeePassword(
                                                              employee.email);
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'تم إرسال بريد إعادة التعيين بنجاح',
                                                              style: GoogleFonts.cairo(),
                                                            ),
                                                            backgroundColor:
                                                                AppColors.success,
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'فشل إرسال بريد إعادة التعيين',
                                                              style: GoogleFonts.cairo(),
                                                            ),
                                                            backgroundColor:
                                                                AppColors.error,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.warning,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'إرسال',
                                                    style: GoogleFonts.cairo(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                          size: 22,
                                        ),
                                        tooltip: 'حذف الموظف',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Text(
                                                'حذف الموظف',
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'هل أنت متأكد من حذف ${employee.name}؟',
                                                style: GoogleFonts.cairo(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: Text(
                                                    'إلغاء',
                                                    style: GoogleFonts.cairo(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    context
                                                        .read<EmployeeCubit>()
                                                        .deleteEmployee(employee.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.error,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'حذف',
                                                    style: GoogleFonts.cairo(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
