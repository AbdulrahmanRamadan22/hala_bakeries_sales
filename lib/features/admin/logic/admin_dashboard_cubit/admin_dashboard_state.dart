// State for Admin Dashboard
import 'package:equatable/equatable.dart';

enum AdminDashboardStatus { initial, loading, success, failure }

class AdminDashboardState extends Equatable {
  final AdminDashboardStatus status;
  final int totalBranches;
  final int totalEmployees;
  final int totalProducts;
  final int lowStockCount;
  final String? errorMessage;

  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.totalBranches = 0,
    this.totalEmployees = 0,
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        status,
        totalBranches,
        totalEmployees,
        totalProducts,
        lowStockCount,
        errorMessage,
      ];

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    int? totalBranches,
    int? totalEmployees,
    int? totalProducts,
    int? lowStockCount,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      totalBranches: totalBranches ?? this.totalBranches,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
