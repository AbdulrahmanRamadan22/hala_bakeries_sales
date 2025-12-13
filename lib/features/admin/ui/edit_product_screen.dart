import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hala_bakeries_sales/core/helper/number_input_formatter.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _minStockController;
  final _formKey = GlobalKey<FormState>();
  
  late String _selectedCategory;
  late String _selectedUnit;

  final List<String> _categories = ['مخبوزات', 'حلويات', 'مشروبات', 'أخرى'];
  final List<String> _units = ['قطعة', 'كيلو', 'علبة'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _minStockController = TextEditingController(text: widget.product.minStockLevel.toString());
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('مسح الباركود')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() {
                  _barcodeController.text = barcodes.first.rawValue ?? '';
                });
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل المنتج: ${widget.product.name}'),
      ),
      body: Stack(
        children: [
          BlocListener<ProductCubit, ProductState>(
            listener: (context, state) {
              if (state.status == ProductStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث المنتج بنجاح'), backgroundColor: AppColors.success),
                );
                context.pop();
              } else if (state.status == ProductStatus.failure) {
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
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'اسم المنتج'),
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'الباركود',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'الفئة'),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'السعر'),
                              keyboardType: TextInputType.number,
                              inputFormatters: NumberInputFormatters.price(),
                              validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'الوحدة'),
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) => setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minStockController,
                        decoration: const InputDecoration(labelText: 'حد الطلب (أقل كمية)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: NumberInputFormatters.integer(),
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final updatedProduct = ProductModel(
                                id: widget.product.id,
                                name: _nameController.text,
                                barcode: _barcodeController.text,
                                category: _selectedCategory,
                                unit: _selectedUnit,
                                price: double.tryParse(_priceController.text) ?? 0.0,
                                stockQuantity: widget.product.stockQuantity,
                                minStockLevel: int.tryParse(_minStockController.text) ?? 5,
                              );
                              context.read<ProductCubit>().updateProduct(updatedProduct);
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
          ),
          // Loading Overlay
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state.status == ProductStatus.loading) {
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
