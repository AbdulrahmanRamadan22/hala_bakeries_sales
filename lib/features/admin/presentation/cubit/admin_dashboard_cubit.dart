import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/presentation/cubit/admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit() : super(const AdminDashboardState());

  Future<void> loadStats() async {
    emit(const AdminDashboardState(status: AdminDashboardStatus.loading));

    try {
      // TODO: Fetch actual stats from Repositories
      await Future.delayed(const Duration(seconds: 1));

      emit(const AdminDashboardState(
        status: AdminDashboardStatus.success,
        totalBranches: 10,
        totalEmployees: 35,
        totalProducts: 150,
        lowStockItems: 5,
      ));
    } catch (e) {
      emit(const AdminDashboardState(
        status: AdminDashboardStatus.failure,
        errorMessage: 'فشل تحميل البيانات',
      ));
    }
  }
}
