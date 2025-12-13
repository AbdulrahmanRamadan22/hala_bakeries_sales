import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';
import 'package:get_it/get_it.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:hala_bakeries_sales/features/admin/logic/low_stock_cubit/low_stock_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/low_stock_cubit/low_stock_state.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/core/permissions/permission_service.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products once when screen is created (uses cache if already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCubit>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeForSearch() async {
    bool isScanned = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('مسح الباركود للبحث'),
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
                  _searchController.text = barcode;
                });
                context.read<ProductCubit>().searchProducts(barcode);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final branchRepository = GetIt.I<BranchRepository>();
    final productCubit = context.read<ProductCubit>(); // Capture cubit before dialog
    List<BranchModel> branches = [];
    String? selectedBranchId;
    bool isLoadingBranches = true;
    bool importToAllBranches = false; // New variable
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fetch branches once
            if (isLoadingBranches && branches.isEmpty && error == null) {
              branchRepository.getBranches().then((value) {
                if (context.mounted) {
                  setDialogState(() {
                    branches = value;
                    isLoadingBranches = false;
                    if (branches.isNotEmpty) {
                      selectedBranchId = branches.first.id;
                    }
                  });
                }
              }).catchError((e) {
                if (context.mounted) {
                  setDialogState(() {
                    error = 'فشل تحميل الفروع';
                    isLoadingBranches = false;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('استيراد منتجات من إكسل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختر الفرع الذي سيتم إضافة المخزون الابتدائي إليه:',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingBranches)
                    const CircularProgressIndicator()
                  else if (error != null)
                    Text(error!,
                        style: GoogleFonts.cairo(color: AppColors.error))
                  else if (branches.isEmpty)
                    Text('لا توجد فروع متاحة', style: GoogleFonts.cairo())
                  else
                    Column(
                      children: [
                        // Checkbox for all branches
                        CheckboxListTile(
                          title: Text('استيراد لجميع الفروع',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'سيتم إضافة نفس المخزون لكل الفروع',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                          value: importToAllBranches,
                          onChanged: (value) {
                            setDialogState(() {
                              importToAllBranches = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryGreen,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 8),
                        // Branch dropdown (disabled if all branches selected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: importToAllBranches
                                    ? Colors.grey.shade300
                                    : AppColors.primaryGreen),
                            borderRadius: BorderRadius.circular(8),
                            color: importToAllBranches
                                ? Colors.grey.shade100
                                : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBranchId,
                              isExpanded: true,
                              hint: Text('اختر الفرع', style: GoogleFonts.cairo()),
                              items: branches.map((branch) {
                                return DropdownMenuItem(
                                  value: branch.id,
                                  child:
                                      Text(branch.name, style: GoogleFonts.cairo()),
                                );
                              }).toList(),
                              onChanged: importToAllBranches
                                  ? null
                                  : (value) {
                                      setDialogState(() {
                                        selectedBranchId = value;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('إلغاء',
                      style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: (selectedBranchId == null && !importToAllBranches)
                      ? null
                      : () {
                          Navigator.pop(dialogContext); // Close dialog
                          // Use captured cubit instead of context.read
                          productCubit.importProductsFromExcel(
                            importToAllBranches ? null : selectedBranchId!,
                            importToAllBranches: importToAllBranches,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: Text('اختيار ملف و استيراد',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteAllDialog(BuildContext context) async {
    final productCubit = context.read<ProductCubit>();
    final productCount = productCubit.state.products.length;

    if (productCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد منتجات لحذفها', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 8),
              Text('تحذير!', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.error)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من حذف جميع المنتجات؟',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ سيتم حذف $productCount منتج',
                      style: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'هذا الإجراء لا يمكن التراجع عنه!',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                productCubit.deleteAllProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('حذف الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات'),
        elevation: 0,
        actions: [
          FutureBuilder(
            future: getIt<AuthRepository>().getCurrentUser(),
            builder: (context, snapshot) {
              final canEdit = snapshot.hasData && 
                              PermissionService.canEditAdminFeatures(snapshot.data!);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit) ...[
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: AppColors.error,
                        ),
                        tooltip: 'حذف جميع المنتجات',
                        onPressed: () => _showDeleteAllDialog(context),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.upload_file,
                          color: AppColors.primaryGreen,
                        ),
                        tooltip: 'استيراد من إكسل',
                        onPressed: () => _showImportDialog(context),
                      ),
                    ),
                  ],
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: AppColors.primaryGreen),
                      tooltip: 'بحث بالباركود',
                      onPressed: _scanBarcodeForSearch,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
                await context.push('/admin/products/add');
                if (mounted) {
                  context.read<ProductCubit>().loadProducts(forceRefresh: true);
                }
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة منتج',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(),
                decoration: InputDecoration(
                  labelText: 'بحث بالاسم أو الباركود',
                  labelStyle: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryGreen,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductCubit>().loadProducts();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  context.read<ProductCubit>().searchProducts(value);
                },
              ),
            ),
          ),
          // Product List
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state.status == ProductStatus.loading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        if (state.loadingMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.loadingMessage!,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                } else if (state.status == ProductStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'حدث خطأ',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _searchController.text.isEmpty
                                ? Icons.bakery_dining_outlined
                                : Icons.search_off,
                            size: 64,
                            color: AppColors.primaryOrange.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchController.text.isEmpty
                              ? 'لا يوجد منتجات حالياً'
                              : 'لا توجد نتائج',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'ابدأ بإضافة منتج جديد'
                              : 'جرب البحث بكلمات مختلفة',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    final branchDetails =
                        state.branchStockDetails[product.id] ?? [];
                    final totalStock = state.productStocks[product.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryOrange.withOpacity(0.15),
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
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryOrange.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.bakery_dining,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.category,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${product.price} ريال',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 14,
                                      color: totalStock > 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'إجمالي المخزون: $totalStock',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: totalStock > 0
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: FutureBuilder(
                            future: getIt<AuthRepository>().getCurrentUser(),
                            builder: (context, snapshot) {
                              final canEdit = snapshot.hasData && 
                                              PermissionService.canEditAdminFeatures(snapshot.data!);
                              
                              if (!canEdit) {
                                return const SizedBox.shrink();
                              }
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.primaryGreen,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        await context.push('/admin/products/edit',
                                            extra: product);
                                        // No need to reload - edit screen calls loadProducts on save
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
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        final cubit = context.read<ProductCubit>();
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              'حذف المنتج',
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              'هل أنت متأكد من حذف ${product.name}؟',
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
                                                  cubit.deleteProduct(product.id);
                                                  Navigator.pop(ctx);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.error,
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
                              );
                            },
                          ),
                          children: [
                            if (branchDetails.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'لا يوجد مخزون في أي فرع',
                                      style: GoogleFonts.cairo(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...branchDetails.map(
                                (detail) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.store,
                                          size: 18,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          detail.branchName,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: detail.stock > 0
                                              ? AppColors.success
                                                  .withOpacity(0.15)
                                              : AppColors.error
                                                  .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: detail.stock > 0
                                                ? AppColors.success
                                                    .withOpacity(0.3)
                                                : AppColors.error
                                                    .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${detail.stock}',
                                          style: GoogleFonts.cairo(
                                            color: detail.stock > 0
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
