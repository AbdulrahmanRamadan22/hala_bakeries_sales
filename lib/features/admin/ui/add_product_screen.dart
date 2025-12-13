import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hala_bakeries_sales/core/helper/number_input_formatter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _barcode = '';
  String _category = 'مخبوزات';
  String _unit = 'قطعة';
  double _price = 0.0;
  int _reorderLevel = 5;

  final List<String> _categories = ['مخبوزات', 'حلويات', 'مشروبات', 'أخرى'];
  final List<String> _units = ['قطعة', 'حبة', 'كيلو', 'جرام', 'علبة', 'كرتونة', 'رغيف', 'صينية'];

  final _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    bool isScanned = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('مسح الباركود'),
            elevation: 0,
          ),
          body: MobileScanner(
            onDetect: (capture) async {
              if (isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && mounted) {
                isScanned = true;
                await SystemSound.play(SystemSoundType.alert);
                await HapticFeedback.mediumImpact();
                final barcode = (barcodes.first.rawValue ?? '').trim();
                Navigator.pop(context);
                setState(() {
                  _barcodeController.text = barcode;
                });
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
        title: Text(
          'إضافة منتج جديد',
          style: GoogleFonts.cairo(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          BlocListener<ProductCubit, ProductState>(
            listener: (context, state) {
              if (state.status == ProductStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إضافة المنتج بنجاح',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                context.pop();
              } else if (state.status == ProductStatus.failure) {
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'اسم المنتج',
                          hintText: 'أدخل اسم المنتج',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم المنتج';
                          }
                          return null;
                        },
                        onSaved: (value) => _name = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'الباركود',
                          hintText: 'أدخل الباركود',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                        ),
                        onSaved: (value) => _barcode = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'الفئة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              inputFormatters: NumberInputFormatters.price(),
                              decoration: InputDecoration(
                                labelText: 'السعر',
                                hintText: 'أدخل سعر المنتج',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال السعر';
                                }
                                return null;
                              },
                              onSaved: (value) => _price = double.tryParse(value!) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              decoration: InputDecoration(
                                labelText: 'الوحدة',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _units
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) => setState(() => _unit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: NumberInputFormatters.integer(),
                        initialValue: '5',
                        decoration: InputDecoration(
                          labelText: 'حد الطلب',
                          hintText: 'أدخل حد الطلب',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال حد الطلب';
                          }
                          return null;
                        },
                        onSaved: (value) => _reorderLevel = int.tryParse(value!) ?? 0,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              context.read<ProductCubit>().addProduct(
                                    _name,
                                    _barcodeController.text,
                                    _category,
                                    _unit,
                                    _price,
                                    _reorderLevel,
                                  );
                            }
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
                            'حفظ المنتج',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
