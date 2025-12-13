import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_state.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/core/permissions/permissions.dart';
import 'package:hala_bakeries_sales/core/permissions/permission_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final UserModel employee;

  const EditEmployeeScreen({super.key, required this.employee});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _nameController = TextEditingController();
  late String? _selectedBranchId;
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.employee.name;
    _selectedBranchId = widget.employee.branchId;
    _permissions = {
      AppPermissions.canReceiveGoods: widget.employee.permissions.contains(AppPermissions.canReceiveGoods),
      AppPermissions.canRecordDamage: widget.employee.permissions.contains(AppPermissions.canRecordDamage),
      AppPermissions.canViewStock: widget.employee.permissions.contains(AppPermissions.canViewStock),
      AppPermissions.canViewLogs: widget.employee.permissions.contains(AppPermissions.canViewLogs),
      AppPermissions.canDoInventoryCount: widget.employee.permissions.contains(AppPermissions.canDoInventoryCount),
      AppPermissions.canViewAdminFeatures: widget.employee.permissions.contains(AppPermissions.canViewAdminFeatures),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل بيانات: ${widget.employee.name}',
          style: GoogleFonts.cairo(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          BlocListener<EmployeeCubit, EmployeeState>(
            listener: (context, state) {
              if (state.status == EmployeeStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تحديث البيانات بنجاح',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } else if (state.status == EmployeeStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'حدث خطأ',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    Colors.white,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name Section
                      Text(
                        'اسم الموظف:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.2),
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
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.person,
                              color: AppColors.info,
                            ),
                            hintText: 'أدخل اسم الموظف',
                            hintStyle: GoogleFonts.cairo(
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.cairo(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email Display (Read-only)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.employee.email,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Branch Section
                      Text(
                        'نقل الموظف إلى فرع:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<BranchCubit, BranchState>(
                        builder: (context, state) {
                          if (state.status == BranchStatus.loading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return Container(
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
                              value: _selectedBranchId,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.store,
                                  color: AppColors.primaryGreen,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.cairo(
                                color: AppColors.textPrimary,
                              ),
                              items: state.branches
                                  .map((b) => DropdownMenuItem(
                                        value: b.id,
                                        child: Text(
                                          b.name,
                                          style: GoogleFonts.cairo(),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedBranchId = v),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Permissions Section
                      Text(
                        'تعديل الصلاحيات:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.15),
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
                        child: Column(
                          children: _permissions.keys.map((key) {
                            final isLast = key == _permissions.keys.last;
                            final isReadOnlyAdmin = _permissions[AppPermissions.canViewAdminFeatures] ?? false;
                            final isEnabled = key == AppPermissions.canViewAdminFeatures || !isReadOnlyAdmin;

                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: Text(
                                    PermissionService.getPermissionName(key),
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    PermissionService.getPermissionDescription(key),
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  value: _permissions[key],
                                  activeColor: AppColors.primaryGreen,
                                  onChanged: isEnabled ? (val) {
                                    setState(() {
                                      if (key == AppPermissions.canViewAdminFeatures) {
                                        _permissions[key] = val!;
                                        if (val == true) {
                                          for (var k in _permissions.keys) {
                                            if (k != AppPermissions.canViewAdminFeatures) {
                                              _permissions[k] = false;
                                            }
                                          }
                                        }
                                      } else {
                                        _permissions[key] = val!;
                                      }
                                    });
                                  } : null,
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedPermissions = _permissions.entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .toList();

                            // Update name if changed
                            if (_nameController.text != widget.employee.name) {
                              await context.read<EmployeeCubit>().updateEmployeeName(
                                    id: widget.employee.id,
                                    name: _nameController.text,
                                  );
                            }

                            // Update branch and permissions
                            await context.read<EmployeeCubit>().updateEmployee(
                                  id: widget.employee.id,
                                  branchId: _selectedBranchId ?? '',
                                  permissions: selectedPermissions,
                                );
                            
                            if (mounted) context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'حفظ التعديلات',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.error.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'منطقة الأمان',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.error.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Password Reset Section
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'إعادة تعيين كلمة المرور',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سيتم إرسال بريد إلكتروني للموظف لإعادة تعيين كلمة المرور',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.lock_reset, color: AppColors.error),
                                  label: Text(
                                    'إرسال بريد إعادة التعيين',
                                    style: GoogleFonts.cairo(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.error.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        title: Text(
                                          'تأكيد إعادة التعيين',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          'سيتم إرسال بريد إلكتروني إلى ${widget.employee.email} لإعادة تعيين كلمة المرور. هل أنت متأكد؟',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              'إلغاء',
                                              style: GoogleFonts.cairo(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              context.read<EmployeeCubit>().resetEmployeePassword(widget.employee.email);
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم إرسال البريد الإلكتروني',
                                                    style: GoogleFonts.cairo(color: Colors.white),
                                                  ),
                                                  backgroundColor: AppColors.success,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading Overlay
          BlocBuilder<EmployeeCubit, EmployeeState>(
            builder: (context, state) {
              if (state.status == EmployeeStatus.loading) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
