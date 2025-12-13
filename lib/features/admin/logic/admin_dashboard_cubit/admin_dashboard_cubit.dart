import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_state.dart';

import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final BranchRepository _branchRepository;
  final EmployeeRepository _employeeRepository;
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;

  AdminDashboardCubit(
    this._branchRepository,
    this._employeeRepository,
    this._productRepository,
    this._branchStockRepository,
  ) : super(const AdminDashboardState());

  Future<void> loadStats() async {
    emit(const AdminDashboardState(status: AdminDashboardStatus.loading));

    try {
      print('AdminDashboard: Loading branches...');
      final branches = await _branchRepository.getBranches();
      print('AdminDashboard: Loaded ${branches.length} branches');
      
      print('AdminDashboard: Loading employees...');
      final employees = await _employeeRepository.getEmployees();
      print('AdminDashboard: Loaded ${employees.length} employees');
      
      print('AdminDashboard: Loading products...');
      final products = await _productRepository.getProducts();
      print('AdminDashboard: Loaded ${products.length} products');
      
      // Calculate low stock items by checking total stock across all branches
      int lowStockCount = 0;
      for (final product in products) {
        final totalStock = await _branchStockRepository.getTotalProductStock(product.id);
        if (totalStock <= product.minStockLevel) {
          lowStockCount++;
        }
      }
      
      print('AdminDashboard: Found $lowStockCount low stock items');

      emit(AdminDashboardState(
        status: AdminDashboardStatus.success,
        totalBranches: branches.length,
        totalEmployees: employees.length,
        totalProducts: products.length,
        lowStockCount: lowStockCount,
      ));
    } catch (e, stackTrace) {
      print('AdminDashboard Error: $e');
      print('StackTrace: $stackTrace');
      emit(AdminDashboardState(
        status: AdminDashboardStatus.failure,
        errorMessage: 'فشل تحميل البيانات: ${e.toString()}',
      ));
    }
  }
}
