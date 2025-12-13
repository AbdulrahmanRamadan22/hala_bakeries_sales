import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_report_cubit/inventory_report_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_report_cubit/inventory_report_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/inventory_count_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/features/admin/services/inventory_report_pdf_service.dart';
import 'package:hala_bakeries_sales/features/admin/services/inventory_report_excel_service.dart';

class InventoryCountReportScreen extends StatefulWidget {
  const InventoryCountReportScreen({super.key});

  @override
  State<InventoryCountReportScreen> createState() => _InventoryCountReportScreenState();
}

class _InventoryCountReportScreenState extends State<InventoryCountReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedBranchId;
  List<BranchModel> _branches = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndBranches();
  }

  Future<void> _loadUserAndBranches() async {
    final authRepo = getIt<AuthRepository>();
    final user = await authRepo.getCurrentUser();
    
    setState(() {
      _currentUser = user;
    });

    // Load branches for admin users
    if (user?.role == UserRole.admin) {
      final branchRepo = getIt<BranchRepository>();
      final branches = await branchRepo.getBranches();
      setState(() {
        _branches = branches;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryReportCubit(
        inventoryCountRepository: getIt<InventoryCountRepository>(),
      )..fetchReports(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تقارير الجرد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            BlocBuilder<InventoryReportCubit, InventoryReportState>(
              builder: (context, state) {
                if (state.reports.isEmpty) return const SizedBox.shrink();
                
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  tooltip: 'تصدير التقرير',
                  onSelected: (value) {
                    if (value == 'pdf') {
                      _exportToPdf(context, state);
                    } else if (value == 'excel') {
                      _exportToExcel(context, state);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'pdf',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text('تصدير PDF', style: GoogleFonts.cairo()),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'excel',
                      child: Row(
                        children: [
                          const Icon(Icons.table_view, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text('تصدير Excel', style: GoogleFonts.cairo()),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<InventoryReportCubit, InventoryReportState>(
          builder: (context, state) {
            if (state.status == InventoryReportStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == InventoryReportStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'حدث خطأ',
                  style: GoogleFonts.cairo(color: AppColors.error),
                ),
              );
            }

            if (state.reports.isEmpty) {
              return Column(
                children: [
                  _buildFilters(context),
                  Expanded(child: _buildEmptyState()),
                ],
              );
            }

            return Column(
              children: [
                _buildFilters(context),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildSummaryCards(state),
                      ),
                      _buildReportsSliverList(state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'فلترة التقارير',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _startDate == null
                      ? 'من تاريخ'
                      : DateFormat('yyyy-MM-dd').format(_startDate!),
                  onTap: () => _selectStartDate(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: _endDate == null
                      ? 'إلى تاريخ'
                      : DateFormat('yyyy-MM-dd').format(_endDate!),
                  onTap: () => _selectEndDate(context),
                ),
              ),
            ],
          ),
          if (_currentUser?.role == UserRole.admin && _branches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedBranchId,
                decoration: InputDecoration(
                  labelText: 'الفرع',
                  labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.store, color: AppColors.primaryGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: Colors.white,
                style: GoogleFonts.cairo(color: AppColors.textPrimary),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('كل الفروع', style: GoogleFonts.cairo()),
                  ),
                  ..._branches.map((branch) {
                    return DropdownMenuItem<String>(
                      value: branch.id,
                      child: Text(branch.name, style: GoogleFonts.cairo()),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBranchId = value;
                  });
                  context.read<InventoryReportCubit>().updateBranchFilter(value);
                },
              ),
            ),
          ],
          if (_startDate != null || _endDate != null || _selectedBranchId != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedBranchId = null;
                });
                context.read<InventoryReportCubit>().resetFilters();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: Text('إعادة تعيين', style: GoogleFonts.cairo()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext cubitContext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      
      cubitContext.read<InventoryReportCubit>().updateDateFilter(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext cubitContext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      cubitContext.read<InventoryReportCubit>().updateDateFilter(_startDate, _endDate);
    }
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.15),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حساب المبيعات التلقائي',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المبيعات = الكمية المتوقعة - الكمية الفعلية',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(InventoryReportState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'إجمالي الجرود',
                  '${state.totalCounts}',
                  Icons.inventory_2,
                  AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'إجمالي المبيعات',
                  '${state.netVarianceValue.abs().toStringAsFixed(2)} ريال',
                  Icons.shopping_cart,
                  state.netVarianceValue < 0 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'القيمة الفعلية',
                  '${state.totalActualValue.toStringAsFixed(2)} ريال',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'عدد المنتجات',
                  '${state.reports.fold<int>(0, (sum, report) => sum + report.items.length)}',
                  Icons.category,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSliverList(InventoryReportState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final report = state.reports[index];
            final totalVariance = report.items.fold<double>(
              0,
              (sum, item) => sum + (item.expectedQuantity - item.actualQuantity) * item.unitPrice,
            );
            final isSales = totalVariance > 0;
            final varianceColor = isSales ? AppColors.success : AppColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: varianceColor.withOpacity(0.3),
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
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: varianceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSales ? Icons.shopping_cart : Icons.add_circle,
                    color: varianceColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  report.branchName,
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
                          Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy-MM-dd').format(report.date),
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            report.employeeName,
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: varianceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSales ? Icons.shopping_cart : Icons.add_circle,
                              size: 14,
                              color: varianceColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSales 
                                ? 'مبيعات: ${totalVariance.toStringAsFixed(2)} ريال'
                                : 'زيادة: ${totalVariance.toStringAsFixed(2)} ريال',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: varianceColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                onTap: () => _showReportDetails(report),
              ),
            );
          },
          childCount: state.reports.length,
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
            'لا توجد تقارير',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الجرد',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${report.branchName} - ${DateFormat('yyyy-MM-dd').format(report.date)}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_view, color: AppColors.success),
                      tooltip: 'تصدير Excel',
                      onPressed: () async {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'جاري إنشاء ملف Excel...',
                                    style: GoogleFonts.cairo(),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // Generate Excel for single report
                          final file = await InventoryReportExcelService.generateInventoryReportExcel([report]);

                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            _handleExportedFile(context, file);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: AppColors.primaryGreen),
                      tooltip: 'تصدير PDF',
                      onPressed: () async {
                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'جاري إنشاء ملف PDF...',
                                    style: GoogleFonts.cairo(),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // Generate PDF
                          final file = await InventoryReportPdfService.generateInventoryCountPdf(report);

                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            _handleExportedFile(context, file);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: report.items.length,
                  itemBuilder: (context, index) {
                    final item = report.items[index];
                    final variance = item.expectedQuantity - item.actualQuantity;
                    final isSales = variance > 0;
                    final varianceColor = variance == 0
                        ? AppColors.success
                        : (isSales ? AppColors.success : AppColors.warning);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: varianceColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: varianceColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('متوقع:', style: GoogleFonts.cairo(fontSize: 13)),
                              Text('${item.expectedQuantity}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('فعلي:', style: GoogleFonts.cairo(fontSize: 13)),
                              Text('${item.actualQuantity}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (variance != 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSales ? Icons.shopping_cart : Icons.add_circle,
                                      size: 14,
                                      color: varianceColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSales ? 'مبيعات:' : 'زيادة:',
                                      style: GoogleFonts.cairo(fontSize: 13),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${variance.abs()}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: varianceColor,
                                  ),
                                ),
                              ],
                            ),
                          if (item.note != null && item.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ملاحظة: ${item.note}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to handle exported file (Open or Share)
  Future<void> _handleExportedFile(BuildContext context, File file) async {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تم تصدير الملف بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد فتح الملف أم مشاركته؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(file.path)], text: 'تقرير الجرد');
            },
            icon: const Icon(Icons.share),
            label: Text('مشاركة', style: GoogleFonts.cairo()),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              OpenFile.open(file.path);
            },
            icon: const Icon(Icons.open_in_new),
            label: Text('فتح', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context, InventoryReportState state) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جاري إنشاء ملف Excel...',
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
        ),
      );

      // Generate Excel
      final file = await InventoryReportExcelService.generateInventoryReportExcel(state.reports);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        _handleExportedFile(context, file);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  



  Future<void> _exportToPdf(BuildContext context, InventoryReportState state) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جاري إنشاء ملف PDF...',
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
        ),
      );

      // Generate PDF
      final file = await InventoryReportPdfService.generateMultipleReportsPdf(
        state.reports,
        state.startDate,
        state.endDate,
        state.selectedBranchId != null
            ? _branches.firstWhere((b) => b.id == state.selectedBranchId).name
            : null,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        _handleExportedFile(context, file);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تصدير التقرير: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
