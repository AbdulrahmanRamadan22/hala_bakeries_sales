class Routes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';

  // Admin Routes
  static const String adminDashboard = '/admin-dashboard';
  static const String branchList = '/admin/branches';
  static const String addBranch = '/admin/branches/add';
  static const String productList = '/admin/products';
  static const String addProduct = '/admin/products/add';
  static const String employeeList = '/admin/employees';
  static const String addEmployee = '/admin/employees/add';
  static const String addAdmin = '/admin/admins/add';
  static const String changePassword = '/admin/change-password';
  static const String reports = '/admin/reports';
  static const String adminEmployeeLogs = '/admin/employee-logs';
  static const String openingBalance = '/admin/opening-balance';
  static const String lowStock = '/admin/low-stock';
  static const String adminInventoryCount = '/admin/inventory-count';
  static const String adminInventoryCountReport = '/admin/inventory-count/report';

  // Employee Routes
  static const String employeeDashboard = '/employee-dashboard';
  static const String receiveGoods = '/employee/receive';
  static const String recordDamage = '/employee/damage';
  static const String viewStock = '/employee/stock';
  static const String employeeLogs = '/employee/logs';
  static const String employeeInventoryCount = '/employee/inventory-count';

  // Shared Routes
  static const String barcodeScanner = '/scanner';
}
