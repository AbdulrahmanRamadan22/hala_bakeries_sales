import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/theming/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_state.dart';
import 'package:hala_bakeries_sales/core/routing/routes_string.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboardView();
  }
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    // Load data when screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardCubit>().loadStats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data whenever we return to this screen
    // This ensures fresh data after deleting items
    context.read<AdminDashboardCubit>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              context.read<AdminDashboardCubit>().loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          if (state.status == AdminDashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AdminDashboardStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      'حدث خطأ في تحميل البيانات',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'حدث خطأ غير معروف',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AdminDashboardCubit>().loadStats();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  Colors.white,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.lightGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'نظرة عامة',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'الفروع',
                      '${state.totalBranches}',
                      Icons.store,
                      Colors.blue,
                      () async {
                        await context.push('/admin/branches');
                        if (context.mounted) {
                          context.read<AdminDashboardCubit>().loadStats();
                        }
                      },
                    ),
                    _buildStatCard(
                      'المنتجات',
                      '${state.totalProducts}',
                      Icons.shopping_bag,
                      Colors.green,
                      () async {
                        await context.push('/admin/products');
                        if (context.mounted) {
                          context.read<AdminDashboardCubit>().loadStats();
                        }
                      },
                    ),
                    _buildStatCard(
                      'الموظفين',
                      '${state.totalEmployees}',
                      Icons.people,
                      Colors.orange,
                      () async {
                        await context.push('/admin/employees');
                        if (context.mounted) {
                          context.read<AdminDashboardCubit>().loadStats();
                        }
                      },
                    ),
                    _buildStatCard(
                      'نقص المخزون',
                      '${state.lowStockCount}',
                      Icons.warning,
                      Colors.red,
                      () async {
                        await context.push(Routes.lowStock);
                        if (context.mounted) {
                          context.read<AdminDashboardCubit>().loadStats();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuTile(
                  context,
                  'إدارة الفروع',
                  'إضافة وتعديل الفروع',
                  Icons.store_mall_directory,
                  () async {
                    await context.push('/admin/branches');
                    if (context.mounted) {
                      context.read<AdminDashboardCubit>().loadStats();
                    }
                  },
                ),
                _buildMenuTile(
                  context,
                  'إدارة المنتجات',
                  'إضافة وتعديل المنتجات والأسعار',
                  Icons.bakery_dining,
                  () async {
                    await context.push('/admin/products');
                    if (context.mounted) {
                      context.read<AdminDashboardCubit>().loadStats();
                    }
                  },
                ),
                _buildMenuTile(
                  context,
                  'إدارة الموظفين',
                  'إضافة موظفين وتحديد الصلاحيات',
                  Icons.badge,
                  () async {
                    await context.push('/admin/employees');
                    if (context.mounted) {
                      context.read<AdminDashboardCubit>().loadStats();
                    }
                  },
                ),
                _buildMenuTile(
                  context,
                  'رصيد افتتاحي',
                  'تسجيل المخزون الافتتاحي لكل فرع',
                  Icons.inventory,
                  () => context.push(Routes.openingBalance),
                ),
                _buildMenuTile(
                  context,
                  'التقارير',
                  'عرض تقارير المبيعات والمخزون',
                  Icons.bar_chart,
                  () => context.push('/admin/reports'),
                ),
                _buildMenuTile(
                  context,
                  'تقارير الجرد',
                  'عرض ومراجعة تقارير الجرد والمبيعات',
                  Icons.assessment,
                  () => context.push(Routes.adminInventoryCountReport),
                ),
                _buildMenuTile(
                  context,
                  'سجل العمليات',
                  'مشاهدة جميع عمليات الموظفين',
                  Icons.history,
                  () => context.push('/admin/employee-logs'),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.15),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryGreen.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
