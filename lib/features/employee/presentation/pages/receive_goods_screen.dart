import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/receive_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/receive_state.dart';

class ReceiveGoodsScreen extends StatefulWidget {
  const ReceiveGoodsScreen({super.key});

  @override
  State<ReceiveGoodsScreen> createState() => _ReceiveGoodsScreenState();
}

class _ReceiveGoodsScreenState extends State<ReceiveGoodsScreen> {
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
        title: const Text('استلام بضاعة'),
      ),
      body: BlocListener<ReceiveCubit, ReceiveState>(
        listener: (context, state) {
          if (state.status == ReceiveStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسجيل الاستلام بنجاح'), backgroundColor: AppColors.success),
            );
            context.pop();
          } else if (state.status == ReceiveStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'حدث خطأ'), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<ReceiveCubit, ReceiveState>(
          builder: (context, state) {
            if (state.status == ReceiveStatus.loading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: state.selectedProductId,
                        decoration: const InputDecoration(labelText: 'المنتج'),
                        items: state.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: (v) => context.read<ReceiveCubit>().selectProduct(v!),
                        validator: (value) => value == null ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'الكمية المستلمة'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                              : const Text('تأكيد الاستلام'),
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
