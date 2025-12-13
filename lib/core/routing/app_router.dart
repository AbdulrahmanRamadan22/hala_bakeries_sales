import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hala_bakeries_sales/core/di/dependency_injection.dart';
import 'package:hala_bakeries_sales/core/routing/routes_string.dart';

// Repositories
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';

// Cubits
import 'package:hala_bakeries_sales/features/auth/logic/splash_cubit/splash_cubit.dart';
import 'package:hala_bakeries_sales/features/auth/logic/login_cubit/login_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/report_cubit/report_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/logic/receive_cubit/receive_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/logic/damage_cubit/damage_cubit.dart';
import 'package:hala_bakeries_sales/features/employee/logic/stock_cubit/stock_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/low_stock_cubit/low_stock_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/inventory_count_cubit/inventory_count_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/add_admin_cubit/add_admin_cubit.dart';
import 'package:hala_bakeries_sales/features/admin/logic/change_password_cubit/change_password_cubit.dart';

// Screens
import 'package:hala_bakeries_sales/features/auth/ui/splash_screen.dart';
import 'package:hala_bakeries_sales/features/auth/ui/login_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/admin_dashboard_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/branch_list_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/add_branch_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/edit_branch_screen.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';
import 'package:hala_bakeries_sales/features/admin/ui/product_list_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/add_product_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/edit_product_screen.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:hala_bakeries_sales/features/admin/ui/employee_list_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/add_employee_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/edit_employee_screen.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/features/admin/ui/reports_screen.dart';
import 'package:hala_bakeries_sales/features/employee/ui/employee_dashboard_screen.dart';
import 'package:hala_bakeries_sales/features/employee/ui/receive_goods_screen.dart';
import 'package:hala_bakeries_sales/features/employee/ui/damage_screen.dart';
import 'package:hala_bakeries_sales/features/employee/ui/stock_screen.dart';
import 'package:hala_bakeries_sales/features/shared/ui/barcode_scanner_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/low_stock_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/inventory_count_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/inventory_count_report_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/add_admin_screen.dart';
import 'package:hala_bakeries_sales/features/admin/ui/change_password_screen.dart';

import '../../features/admin/logic/admin_logs_cubit/admin_logs_cubit.dart';
import '../../features/admin/ui/admin_employee_logs_screen.dart';
import '../../features/employee/logic/employee_logs_cubit/employee_logs_cubit.dart';
import '../../features/employee/ui/employee_logs_screen.dart';
import '../../features/admin/logic/opening_balance_cubit/opening_balance_cubit.dart';
import '../../features/admin/ui/opening_balance_screen.dart';
import '../../features/admin/data/repo/branch_stock_repository.dart';
import '../../features/admin/data/repo/inventory_count_repository.dart';

class AppRouter {
  static GoRouter createRouter() {
    // Get repositories from dependency injection
    final authRepository = getIt<AuthRepository>();
    final branchRepository = getIt<BranchRepository>();
    final productRepository = getIt<ProductRepository>();
    final employeeRepository = getIt<EmployeeRepository>();
    final transactionRepository = getIt<TransactionRepository>();

    return GoRouter(
      initialLocation: Routes.splash,
      routes: [
        // Auth Routes
        GoRoute(
          path: Routes.splash,
          builder: (context, state) => BlocProvider(
            create: (context) => SplashCubit(authRepository)..checkAuthStatus(),
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => BlocProvider(
            create: (context) => LoginCubit(authRepository),
            child: const LoginScreen(),
          ),
        ),

        // Admin Routes
        GoRoute(
          path: Routes.adminDashboard,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return BlocProvider(
              create: (context) => AdminDashboardCubit(
                branchRepository,
                employeeRepository,
                productRepository,
                branchStockRepository,
              )..loadStats(),
              child: const AdminDashboard(),
            );
          },
        ),
        GoRoute(
          path: Routes.branchList,
          builder: (context, state) {
            return BlocProvider(
              create: (context) =>
                  BranchCubit(branchRepository)..loadBranches(),
              child: const BranchListScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) {
                return BlocProvider(
                  create: (context) => BranchCubit(branchRepository),
                  child: const AddBranchScreen(),
                );
              },
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final branch = state.extra as BranchModel;
                return BlocProvider(
                  create: (context) => BranchCubit(branchRepository),
                  child: EditBranchScreen(branch: branch),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.productList,
          builder: (context, state) {
            // Use singleton ProductCubit to prevent unnecessary reloads
            return BlocProvider.value(
              value: getIt<ProductCubit>(),
              child: const ProductListScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) {
                final branchStockRepository = getIt<BranchStockRepository>();
                return BlocProvider(
                  create: (context) => ProductCubit(productRepository, branchStockRepository, branchRepository),
                  child: const AddProductScreen(),
                );
              },
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final product = state.extra as ProductModel;
                final branchStockRepository = getIt<BranchStockRepository>();
                return BlocProvider(
                  create: (context) => ProductCubit(productRepository, branchStockRepository, branchRepository),
                  child: EditProductScreen(product: product),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.employeeList,
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => EmployeeCubit(employeeRepository)..loadEmployees(),
                ),
                BlocProvider(
                  create: (context) => BranchCubit(branchRepository)..loadBranches(),
                ),
              ],
              child: const EmployeeListScreen(),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => EmployeeCubit(employeeRepository),
                    ),
                    BlocProvider(
                      create: (context) =>
                          BranchCubit(branchRepository)..loadBranches(),
                    ),
                  ],
                  child: const AddEmployeeScreen(),
                );
              },
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final employee = state.extra as UserModel;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => EmployeeCubit(employeeRepository),
                    ),
                    BlocProvider(
                      create: (context) =>
                          BranchCubit(branchRepository)..loadBranches(),
                    ),
                  ],
                  child: EditEmployeeScreen(employee: employee),
                );
              },
            ),
          ],
        ),

        GoRoute(
          path: Routes.addAdmin,
          builder: (context, state) {
            return BlocProvider(
              create: (context) => AddAdminCubit(employeeRepository),
              child: const AddAdminScreen(),
            );
          },
        ),

        GoRoute(
          path: Routes.changePassword,
          builder: (context, state) {
            return BlocProvider(
              create: (context) => ChangePasswordCubit(authRepository),
              child: const ChangePasswordScreen(),
            );
          },
        ),

        GoRoute(
          path: Routes.reports,
          builder: (context, state) {
            return BlocProvider(
              create: (context) =>
                  ReportCubit(transactionRepository, productRepository, employeeRepository)..loadReports(),
              child: const ReportsScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.adminEmployeeLogs,
          builder: (context, state) {
            final employeeId = state.extra as String?;
            return BlocProvider(
              create: (context) =>
                  AdminLogsCubit(transactionRepository, employeeRepository, productRepository)
                    ..loadInitialData(employeeId: employeeId),
              child: AdminEmployeeLogsScreen(employeeId: employeeId),
            );
          },
        ),
        GoRoute(
          path: Routes.openingBalance,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return BlocProvider(
              create: (context) => OpeningBalanceCubit(
                branchRepository,
                productRepository,
                branchStockRepository,
                transactionRepository,
              )..loadInitialData(),
              child: const OpeningBalanceScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.lowStock,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return BlocProvider(
              create: (context) => LowStockCubit(
                productRepository,
                branchRepository,
                branchStockRepository,
              )..loadLowStockItems(),
              child: const LowStockScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.adminInventoryCount,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            final inventoryCountRepository = getIt<InventoryCountRepository>();
            return BlocProvider(
              create: (context) => InventoryCountCubit(
                inventoryCountRepository: inventoryCountRepository,
                productRepository: productRepository,
                branchStockRepository: branchStockRepository,
                transactionRepository: transactionRepository,
              ),
              child: const InventoryCountScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.adminInventoryCountReport,
          builder: (context, state) {
            return const InventoryCountReportScreen();
          },
        ),

        // Employee Routes
        GoRoute(
          path: Routes.employeeDashboard,
          builder: (context, state) => const EmployeeDashboard(),
        ),
        GoRoute(
          path: Routes.receiveGoods,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return _ReceiveGoodsScreenWrapper(
              productRepository: productRepository,
              branchStockRepository: branchStockRepository,
              transactionRepository: transactionRepository,
            );
          },
        ),
        GoRoute(
          path: Routes.recordDamage,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return _DamageScreenWrapper(
              productRepository: productRepository,
              branchStockRepository: branchStockRepository,
              transactionRepository: transactionRepository,
            );
          },
        ),
        GoRoute(
          path: Routes.viewStock,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            return _StockScreenWrapper(
              productRepository: productRepository,
              branchStockRepository: branchStockRepository,
            );
          },
        ),
        GoRoute(
          path: Routes.employeeLogs,
          builder: (context, state) {
            return BlocProvider(
              create: (context) =>
                  EmployeeLogsCubit(transactionRepository, productRepository)
                    ..loadMyTransactions(),
              child: const EmployeeLogsScreen(),
            );
          },
        ),
        GoRoute(
          path: Routes.employeeInventoryCount,
          builder: (context, state) {
            final branchStockRepository = getIt<BranchStockRepository>();
            final inventoryCountRepository = getIt<InventoryCountRepository>();
            return BlocProvider(
              create: (context) => InventoryCountCubit(
                inventoryCountRepository: inventoryCountRepository,
                productRepository: productRepository,
                branchStockRepository: branchStockRepository,
                transactionRepository: transactionRepository,
              ),
              child: const InventoryCountScreen(),
            );
          },
        ),

        // Shared Routes
        GoRoute(
          path: Routes.barcodeScanner,
          builder: (context, state) => const BarcodeScannerScreen(),
        ),
      ],
    );
  }
}

// Wrapper widgets to handle async user loading
class _ReceiveGoodsScreenWrapper extends StatelessWidget {
  final ProductRepository productRepository;
  final BranchStockRepository branchStockRepository;
  final TransactionRepository transactionRepository;

  const _ReceiveGoodsScreenWrapper({
    required this.productRepository,
    required this.branchStockRepository,
    required this.transactionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: getIt<AuthRepository>().getCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        return BlocProvider(
          create: (context) => ReceiveCubit(
            productRepository,
            branchStockRepository,
            transactionRepository,
            user?.branchId ?? '',
            user?.id ?? '',
          )..loadProducts(),
          child: const ReceiveGoodsScreen(),
        );
      },
    );
  }
}

class _DamageScreenWrapper extends StatelessWidget {
  final ProductRepository productRepository;
  final BranchStockRepository branchStockRepository;
  final TransactionRepository transactionRepository;

  const _DamageScreenWrapper({
    required this.productRepository,
    required this.branchStockRepository,
    required this.transactionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: getIt<AuthRepository>().getCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        return BlocProvider(
          create: (context) => DamageCubit(
            productRepository,
            branchStockRepository,
            transactionRepository,
            user?.branchId ?? '',
            user?.id ?? '',
          )..loadProducts(),
          child: const DamageScreen(),
        );
      },
    );
  }
}

class _StockScreenWrapper extends StatelessWidget {
  final ProductRepository productRepository;
  final BranchStockRepository branchStockRepository;

  const _StockScreenWrapper({
    required this.productRepository,
    required this.branchStockRepository,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: getIt<AuthRepository>().getCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        return BlocProvider(
          create: (context) => StockCubit(
            productRepository,
            branchStockRepository,
            user?.branchId ?? '',
          )..loadStock(),
          child: const StockScreen(),
        );
      },
    );
  }
}
