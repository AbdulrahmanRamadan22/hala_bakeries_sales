import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/employee/logic/damage_cubit/damage_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/logic/damage_cubit/damage_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:collection/collection.dart';
import 'package:hala_bakeries_sales/core/helper/number_input_formatter.dart';

class DamageScreen extends StatefulWidget {
  const DamageScreen({super.key});

  @override
  State<DamageScreen> createState() => _DamageScreenState();
}

class _DamageScreenState extends State<DamageScreen> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;

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
        title: Text(
          'تسجيل تالف',
          style: GoogleFonts.cairo(),
        ),
        elevation: 0,
      ),
      body: BlocListener<DamageCubit, DamageState>(
        listener: (context, state) {
          if (state.status == DamageStatus.submitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل التالف بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state.status == DamageStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'حدث خطأ'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<DamageCubit, DamageState>(
          builder: (context, state) {
            if (state.status == DamageStatus.loading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Product selection and add to cart section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product dropdown with scanner
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<ProductModel>(
                                  decoration: const InputDecoration(
                                    labelText: 'اختر المنتج',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedProduct,
                                  items: state.products.map((product) {
                                    return DropdownMenuItem(
                                      value: product,
                                      child: Text(product.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProduct = value;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: () async {
                                  final barcode = await context.push<String>('/scanner');
                                  if (barcode != null) {
                                    final product = state.products.firstWhereOrNull(
                                      (p) => p.barcode == barcode,
                                    );
                                    if (product != null) {
                                      setState(() {
                                        _selectedProduct = product;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('المنتج غير موجود')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quantity input
                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: NumberInputFormatters.integer(),
                            validator: (value) =>
                                value!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),

                          // Add to cart button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('إضافة للقائمة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate() &&
                                    _selectedProduct != null) {
                                  final quantity =
                                      double.tryParse(_quantityController.text) ?? 0;
                                  if (quantity > 0) {
                                    context
                                        .read<DamageCubit>()
                                        .addToCart(_selectedProduct!.id, quantity);
                                    _quantityController.clear();
                                    _selectedProduct = null;
                                    setState(() {});
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Cart items list
                          if (state.cart.isNotEmpty) ...[
                            Text(
                              'المنتجات التالفة:',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...state.cart.entries.map((entry) {
                              final product = state.products.firstWhereOrNull(
                                (p) => p.id == entry.key,
                              );
                              if (product == null) return const SizedBox();

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    child: Text(
                                      '${entry.value.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Text('الكمية: ${entry.value.toInt()}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      context
                                          .read<DamageCubit>()
                                          .removeFromCart(entry.key);
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],

                          // Notes field
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom save button
                if (state.cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.status == DamageStatus.submitting
                            ? null
                            : () {
                                context
                                    .read<DamageCubit>()
                                    .submitBatch(_notesController.text);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.status == DamageStatus.submitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'حفظ الكل (${state.cart.length} منتج)',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
