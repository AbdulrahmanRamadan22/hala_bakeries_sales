import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';

class EditBranchScreen extends StatefulWidget {
  final BranchModel branch;

  const EditBranchScreen({super.key, required this.branch});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _locationController = TextEditingController(text: widget.branch.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الفرع: ${widget.branch.name}'),
      ),
      body: Stack(
        children: [
          BlocListener<BranchCubit, BranchState>(
            listener: (context, state) {
              if (state.status == BranchStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الفرع بنجاح'), backgroundColor: AppColors.success),
                );
                context.pop();
              } else if (state.status == BranchStatus.failure) {
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
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم الفرع'),
                      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'العنوان / الموقع'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final updatedBranch = BranchModel(
                              id: widget.branch.id,
                              name: _nameController.text,
                              location: _locationController.text,
                              createdAt: widget.branch.createdAt,
                            );
                            context.read<BranchCubit>().updateBranch(updatedBranch);
                          }
                        },
                        child: const Text('حفظ التعديلات'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Loading Overlay
          BlocBuilder<BranchCubit, BranchState>(
            builder: (context, state) {
              if (state.status == BranchStatus.loading) {
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
