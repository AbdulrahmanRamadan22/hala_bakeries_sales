import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/damage_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/damage_state.dart';

class DamageScreen extends StatefulWidget {
  const DamageScreen({super.key});

  @override
  State<DamageScreen> createState() => _DamageScreenState();
}

class _DamageScreenState extends State<DamageScreen> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل تالف / هالك'),
      ),
      body: BlocListener<DamageCubit, DamageState>(
        listener: (context, state) {
          if (state.status == DamageStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم التسجيل بنجاح'), backgroundColor: AppColors.success),
            );
            context.pop();
          } else if (state.status == DamageStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'حدث خطأ'), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<DamageCubit, DamageState>(
          builder: (context, state) {
            if (state.status == DamageStatus.loading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Type Selection
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<DamageType>(
                              title: const Text('تالف (Damaged)'),
                              value: DamageType.damage,
                              groupValue: state.type,
                              onChanged: (val) => context.read<DamageCubit>().setType(val!),
                              activeColor: AppColors.warning,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<DamageType>(
                              title: const Text('هالك (Waste)'),
                              value: DamageType.spoilage,
                              groupValue: state.type,
                              onChanged: (val) => context.read<DamageCubit>().setType(val!),
                              activeColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: state.selectedProductId,
                        decoration: const InputDecoration(labelText: 'المنتج'),
                        items: state.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: (v) => context.read<DamageCubit>().selectProduct(v!),
                        validator: (value) => value == null ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'الكمية'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                          ),
                          child: state.status == DamageStatus.loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تسجيل العملية'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
