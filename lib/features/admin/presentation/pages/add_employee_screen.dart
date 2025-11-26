import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_state.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedBranchId;
  // Mock Branches for Dropdown
  final List<Map<String, String>> _branches = [
    {'id': '1', 'name': 'فرع وسط البلد'},
    {'id': '2', 'name': 'فرع المعادي'},
    {'id': '3', 'name': 'فرع مدينة نصر'},
  ];

  final Map<String, bool> _permissions = {
    'receive_stock': false,
    'record_damage': false,
    'view_stock': true, // Default
    'view_reports': false,
  };

  final Map<String, String> _permissionLabels = {
    'receive_stock': 'استلام بضاعة',
    'record_damage': 'تسجيل تالف/هالك',
    'view_stock': 'عرض المخزون',
    'view_reports': 'عرض التقارير',
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة موظف جديد'),
      ),
      body: BlocListener<EmployeeCubit, EmployeeState>(
        listener: (context, state) {
          if (state.status == EmployeeStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة الموظف بنجاح'), backgroundColor: AppColors.success),
            );
            context.pop();
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
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                    validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBranchId,
                    decoration: const InputDecoration(labelText: 'الفرع'),
                    items: _branches.map((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']!))).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                    validator: (value) => value == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('الصلاحيات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._permissions.keys.map((key) {
                    return CheckboxListTile(
                      title: Text(_permissionLabels[key] ?? key),
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
                                _usernameController.text,
                                _passwordController.text,
                                _selectedBranchId!,
                                selectedPermissions,
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
    );
  }
}
