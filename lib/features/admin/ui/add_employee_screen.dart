import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_state.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart';
import 'package:hala_bakeries_sales/core/permissions/permissions.dart';
import 'package:hala_bakeries_sales/core/permissions/permission_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedBranchId;

  final Map<String, bool> _permissions = {
    AppPermissions.canReceiveGoods: true,
    AppPermissions.canRecordDamage: true,
    AppPermissions.canViewStock: true,
    AppPermissions.canViewLogs: true,
    AppPermissions.canDoInventoryCount: false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة موظف جديد'),
      ),
      body: Stack(
        children: [
          BlocListener<EmployeeCubit, EmployeeState>(
            listener: (context, state) {
              if (state.status == EmployeeStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة الموظف بنجاح'), backgroundColor: AppColors.success),
                );
                context.pop();
              } else if (state.status == EmployeeStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'حدث خطأ'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم الموظف'),
                    validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return 'مطلوب';
                      if (!value.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<BranchCubit, BranchState>(
                    builder: (context, state) {
                      if (state.status == BranchStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state.status == BranchStatus.failure) {
                        return Text('فشل تحميل الفروع: ${state.errorMessage}', style: const TextStyle(color: Colors.red));
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedBranchId,
                        decoration: const InputDecoration(labelText: 'الفرع'),
                        items: state.branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                        validator: (value) => value == null ? 'مطلوب' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('الصلاحيات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._permissions.keys.map((key) {
                    return CheckboxListTile(
                      title: Text(PermissionService.getPermissionName(key)),
                      subtitle: Text(
                        PermissionService.getPermissionDescription(key),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _permissions[key],
                      onChanged: (val) {
                        setState(() {
                          _permissions[key] = val!;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final selectedPermissions = _permissions.entries
                              .where((e) => e.value)
                              .map((e) => e.key)
                              .toList();
                          
                          context.read<EmployeeCubit>().addEmployee(
                                name: _nameController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                                branchId: _selectedBranchId!,
                                permissions: selectedPermissions,
                              );
                        }
                      },
                      child: const Text('حفظ'),
                    ),
                  ),
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
