import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_dashboard_state.dart';

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

  Future<void> loadStats({bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (!forceRefresh && state.status == AdminDashboardStatus.success) {
      return;
    }

    emit(const AdminDashboardState(status: AdminDashboardStatus.loading));

    try {
      print('AdminDashboard: Loading statistics using count queries...');
      
      // Use count queries instead of fetching all data - much faster!
      final branchesCountFuture = _branchRepository.getBranchesCount();
      final employeesCountFuture = _employeeRepository.getEmployeesCount();
      final productsCountFuture = _productRepository.getProductsCount();
      
      // Execute all count queries in parallel
      final results = await Future.wait([
        branchesCountFuture,
        employeesCountFuture,
        productsCountFuture,
      ]);
      
      final branchesCount = results[0];
      final employeesCount = results[1];
      final productsCount = results[2];
      
      print('AdminDashboard: Loaded statistics - Branches: $branchesCount, Employees: $employeesCount, Products: $productsCount');
      
      emit(AdminDashboardState(
        status: AdminDashboardStatus.success,
        totalBranches: branchesCount,
        totalEmployees: employeesCount,
        totalProducts: productsCount,
        lowStockCount: 0, // Will be updated by background calculation
      ));

      // Calculate low stock in background
      _calculateLowStockInBackground();

    } catch (e, stackTrace) {
      print('AdminDashboard Error: $e');
      print('StackTrace: $stackTrace');
      emit(AdminDashboardState(
        status: AdminDashboardStatus.failure,
        errorMessage: 'فشل تحميل البيانات: ${e.toString()}',
      ));
    }
  }

  Future<void> _calculateLowStockInBackground() async {
    try {
      print('AdminDashboard: Calculating low stock in background...');
      final products = await _productRepository.getProducts();
      
      int lowStockCount = 0;
      
      // Use batch processing for performance (same as LowStockCubit)
      const batchSize = 20;
      for (var i = 0; i < products.length; i += batchSize) {
        final end = (i + batchSize < products.length) ? i + batchSize : products.length;
        final batch = products.sublist(i, end);
        
        // Process batch in parallel
        final batchResults = await Future.wait(batch.map((product) async {
          try {
            final productBranchStocks = await _branchStockRepository.getProductStocks(product.id);
            final totalStock = productBranchStocks.fold<int>(
              0, (sum, stock) => sum + stock.currentStock);
            
            return totalStock <= product.minStockLevel ? 1 : 0;
          } catch (e) {
            return 0;
          }
        }));
        
        lowStockCount += batchResults.reduce((a, b) => a + b);
      }
      
      print('AdminDashboard: Background calculation finished. Low stock items: $lowStockCount');
      
      // Update state with calculated count
      // Check if state is still mounted/valid before emitting
      if (!isClosed) {
        emit(state.copyWith(lowStockCount: lowStockCount));

      }
    } catch (e) {
      print('AdminDashboard: Error calculating low stock: $e');
      // No need to emit failure, just keep showing 0 or previous value
    }
  }
}
