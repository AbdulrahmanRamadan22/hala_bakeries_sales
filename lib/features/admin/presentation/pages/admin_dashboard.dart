import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hala_bakeries_sales/core/constants/app_colors.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/admin_dashboard_state.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminDashboardCubit()..loadStats(),
      child: const AdminDashboardView(),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        actions: [
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
            return Center(child: Text(state.errorMessage ?? 'حدث خطأ'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظرة عامة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'الفروع',
                      state.totalBranches.toString(),
                      Icons.store,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'الموظفين',
                      state.totalEmployees.toString(),
                      Icons.people,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'المنتجات',
                      state.totalProducts.toString(),
                      Icons.inventory_2,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'نواقص المخزون',
                      state.lowStockItems.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'إدارة النظام',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuTile(
                  context,
                  'إدارة الفروع',
                  'إضافة وتعديل الفروع',
                  Icons.store_mall_directory,
                  () => context.push('/admin/branches'),
                ),
                _buildMenuTile(
                  context,
                  'إدارة المنتجات',
                  'إضافة وتعديل المنتجات والأسعار',
                  Icons.bakery_dining,
                  () => context.push('/admin/products'),
                ),
                _buildMenuTile(
                  context,
                  'إدارة الموظفين',
                  'إضافة موظفين وتحديد الصلاحيات',
                  Icons.badge,
                  () => context.push('/admin/employees'),
                ),
                _buildMenuTile(
                  context,
                  'التقارير',
                  'عرض تقارير المبيعات والمخزون',
                  Icons.bar_chart,
                  () => context.push('/admin/reports'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
