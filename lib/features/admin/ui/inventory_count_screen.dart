import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_count_cubit/inventory_count_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_count_cubit/inventory_count_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_item_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/core/helper/number_input_formatter.dart';
import 'package:hala_bakeries_sales/core/routing/routes_string.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  UserModel? _currentUser;
  String? _branchId;
  String? _branchName;

  @override
  void initState() {
    super.initState();
    _loadUserAndInitialize();
  }



  Future<void> _loadUserAndInitialize() async {
    try {
      final authRepo = getIt<AuthRepository>();
      final user = await authRepo.getCurrentUser();
      
      if (user != null) {
        setState(() {
          _currentUser = user;
        });

        // Admin users should use the report screen instead
        if (user.role == UserRole.admin) {
          // Show message and redirect
          return;
        }

        // For employees, use their assigned branch
        if (user.branchId != null) {
          setState(() {
            _branchId = user.branchId;
          });

          final branchRepo = getIt<BranchRepository>();
          final branch = await branchRepo.getBranch(user.branchId!);
          setState(() {
            _branchName = branch?.name ?? 'غير معروف';
          });

          // Initialize inventory count
          if (mounted && _branchId != null && _branchName != null) {
            context.read<InventoryCountCubit>().initializeInventoryCount(
                  branchId: _branchId!,
                  branchName: _branchName!,
                  user: user,
                );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الجرد اليومي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          BlocBuilder<InventoryCountCubit, InventoryCountState>(
            builder: (context, state) {
              if (!state.isWithinTimeWindow && _currentUser?.role != UserRole.admin) {
                return IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    _showTimeWindowInfo();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<InventoryCountCubit, InventoryCountState>(
        listener: (context, state) {
          if (state.status == InventoryCountStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'حدث خطأ'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == InventoryCountStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ الجرد بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
            // Navigate back to home after successful submission
            if (state.currentCount?.status == 'completed') {
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  // Navigate to dashboard based on user role and clear navigation stack
                  final route = _currentUser?.role == UserRole.admin 
                      ? Routes.adminDashboard 
                      : Routes.employeeDashboard;
                  context.go(route);
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state.status == InventoryCountStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check time window for non-admin users
          if (!state.isWithinTimeWindow && _currentUser?.role != UserRole.admin) {
            return _buildTimeWindowError();
          }

          // For admin users, show redirect message to use reports screen
          if (_currentUser?.role == UserRole.admin && _branchId == null) {
            return _buildAdminRedirect();
          }

          if (state.items.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchBar(state),
              _buildSummaryCard(state),
              Expanded(
                child: _buildProductList(state),
              ),
              _buildBottomActions(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeWindowError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time,
                size: 64,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'خارج وقت الجرد',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'الجرد اليومي متاح فقط من الساعة 1:00 صباحاً حتى 3:00 صباحاً',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'العودة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAdminRedirect() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'صفحة الموظفين فقط',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'الجرد اليومي يتم بواسطة الموظفين فقط.\nكمسؤول، يمكنك مراجعة تقارير الجرد والإحصائيات.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.adminInventoryCountReport),
              icon: const Icon(Icons.assessment),
              label: Text(
                'عرض تقارير الجرد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'العودة للوحة التحكم',
                style: GoogleFonts.cairo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات للجرد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(InventoryCountState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.cairo(),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الباركود',
                hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryGreen),
              onPressed: () => _scanBarcode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(InventoryCountState state) {
    final totalItems = state.items.length;
    final countedItems = state.items.where((item) => item.actualQuantity > 0).length;
    final progress = totalItems > 0 ? countedItems / totalItems : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$countedItems / $totalItems',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(InventoryCountState state) {
    final searchQuery = _searchController.text.toLowerCase();
    final filteredItems = state.items.where((item) {
      if (searchQuery.isEmpty) return true;
      return item.productName.toLowerCase().contains(searchQuery) ||
          item.barcode.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: GoogleFonts.cairo(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildProductCard(item);
      },
    );
  }

  Widget _buildProductCard(InventoryCountItem item) {
    final varianceColor = _getVarianceColor(item.variancePercentage);
    final hasVariance = item.actualQuantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVariance ? varianceColor.withOpacity(0.3) : AppColors.primaryGreen.withOpacity(0.2),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bakery_dining,
            color: AppColors.primaryOrange,
            size: 24,
          ),
        ),
        title: Text(
          item.productName,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildInfoChip('متوقع: ${item.expectedQuantity}', AppColors.info),
                  const SizedBox(width: 8),
                  if (hasVariance)
                    _buildInfoChip(
                      'فعلي: ${item.actualQuantity}',
                      varianceColor,
                    ),
                ],
              ),
              if (hasVariance && item.variance != 0) ...[
                const SizedBox(height: 6),
                _buildVarianceIndicator(item),
              ],
            ],
          ),
        ),
        trailing: hasVariance
            ? Icon(Icons.check_circle, color: AppColors.success, size: 28)
            : Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 28),
        children: [
          _buildCountingSection(item),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVarianceIndicator(InventoryCountItem item) {
    final isPositive = item.variance > 0;
    final icon = isPositive ? Icons.trending_down : Icons.trending_up;
    final color = _getVarianceColor(item.variancePercentage);

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          'فرق: ${item.variance.abs()} (${item.variancePercentage.toStringAsFixed(1)}%)',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCountingSection(InventoryCountItem item) {
    final quantityController = TextEditingController(
      text: item.actualQuantity > 0 ? item.actualQuantity.toString() : '',
    );
    final noteController = TextEditingController(text: item.note ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('الرصيد الافتتاحي', '${item.openingBalance}'),
                  ),
                  Expanded(
                    child: _buildDetailRow('المستلم', '${item.receivedQuantity}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('التالف', '${item.damagedQuantity}'),
                  ),
                  Expanded(
                    child: _buildDetailRow('المتوقع', '${item.expectedQuantity}', isHighlight: true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'الكمية الفعلية:',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: NumberInputFormatters.integer(),
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'أدخل الكمية الفعلية',
            hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check, color: AppColors.success),
              onPressed: () {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                context.read<InventoryCountCubit>().updateActualQuantity(
                      item.productId,
                      quantity,
                      note: noteController.text.isEmpty ? null : noteController.text,
                    );
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          onSubmitted: (value) {
            final quantity = int.tryParse(value) ?? 0;
            context.read<InventoryCountCubit>().updateActualQuantity(
                  item.productId,
                  quantity,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
          },
        ),
        if (item.actualQuantity > 0 && item.variance > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم تسجيل ${item.variance} وحدة كمبيعات تلقائياً',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (item.actualQuantity > 0 && item.variancePercentage > 15) ...[
          const SizedBox(height: 12),
          Text(
            'ملاحظة (اختياري):',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            textDirection: TextDirection.rtl, 
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'اكتب سبب الفرق الكبير',
              hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
            ),
            onChanged: (value) {
              context.read<InventoryCountCubit>().updateActualQuantity(
                    item.productId,
                    item.actualQuantity,
                    note: value.isEmpty ? null : value,
                  );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(InventoryCountState state) {
    final canSave = state.items.any((item) => item.actualQuantity > 0);
    final allCounted = state.items.every((item) => item.actualQuantity > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canSave) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.status == InventoryCountStatus.saving
                    ? null
                    : () => _saveAsDraft(),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  'حفظ مسودة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: !allCounted || state.status == InventoryCountStatus.saving
                  ? null
                  : () => _submitCount(),
              icon: const Icon(Icons.check_circle),
              label: Text(
                'إرسال الجرد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getVarianceColor(double percentage) {
    if (percentage < 5) return AppColors.success;
    if (percentage < 15) return AppColors.warning;
    return AppColors.error;
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
                  _searchController.text = barcode;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  void _showTimeWindowInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'وقت الجرد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'الجرد اليومي متاح فقط من الساعة 1:00 صباحاً حتى 3:00 صباحاً.\n\nيمكن للمسؤولين الوصول في أي وقت.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _saveAsDraft() {
    if (_currentUser == null || _branchId == null || _branchName == null) return;

    context.read<InventoryCountCubit>().saveInventoryCount(
          branchId: _branchId!,
          branchName: _branchName!,
          user: _currentUser!,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
  }

  void _submitCount() {
    if (_currentUser == null || _branchId == null || _branchName == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد الإرسال',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من إرسال الجرد؟\n\n⚠️ تنبيه هام: تأكد من تسجيل جميع التوالف واستلام البضاعة لهذا اليوم قبل الإرسال لتجنب حسابها كمبيعات بالخطأ.',
          style: GoogleFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InventoryCountCubit>().submitInventoryCount(
                    branchId: _branchId!,
                    branchName: _branchName!,
                    user: _currentUser!,
                    notes: _notesController.text.isEmpty ? null : _notesController.text,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
