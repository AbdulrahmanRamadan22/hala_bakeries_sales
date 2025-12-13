import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Import repositories with new paths
import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/firebase_services/employee_firebase_service.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/inventory_count_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Firebase instances
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);


  // Firebase Services
  getIt.registerLazySingleton<EmployeeFirebaseService>(
    () => EmployeeFirebaseService(),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<BranchRepository>(
    () => BranchRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepository(
      firestore: getIt<FirebaseFirestore>(),
      employeeService: getIt<EmployeeFirebaseService>(),
    ),
  );

  getIt.registerLazySingleton<BranchStockRepository>(
    () => BranchStockRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<InventoryCountRepository>(
    () => InventoryCountRepository(firestore: getIt<FirebaseFirestore>()),
  );

  // Cubits will be created on-demand in screens using BlocProvider
  // No need to register them here as they have short lifecycles
}
