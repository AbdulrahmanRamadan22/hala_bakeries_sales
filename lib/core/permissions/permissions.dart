class AppPermissions {
  // Permission constants
  static const String canReceiveGoods = 'can_receive_goods';
  static const String canRecordDamage = 'can_record_damage';
  static const String canViewStock = 'can_view_stock';
  static const String canViewLogs = 'can_view_logs';
  static const String canDoInventoryCount = 'can_do_inventory_count';

  // All available permissions
  static const List<String> allPermissions = [
    canReceiveGoods,
    canRecordDamage,
    canViewStock,
    canViewLogs,
    canDoInventoryCount,
  ];

  // Permission display names in Arabic
  static const Map<String, String> permissionNames = {
    canReceiveGoods: 'استلام بضاعة',
    canRecordDamage: 'تسجيل تالف',
    canViewStock: 'متابعة المخزون',
    canViewLogs: 'مشاهدة السجلات',
    canDoInventoryCount: 'الجرد اليومي',
  };

  // Permission descriptions
  static const Map<String, String> permissionDescriptions = {
    canReceiveGoods: 'السماح بتسجيل استلام البضائع من المنتجات',
    canRecordDamage: 'السماح بتسجيل كميات التالف من المنتجات',
    canViewStock: 'السماح بمتابعة المخزون (الرصيد الافتتاحي + الوارد - التالف)',
    canViewLogs: 'السماح بمشاهدة سجل العمليات الخاصة بالموظف',
    canDoInventoryCount: 'السماح بعمل الجرد اليومي للمنتجات (متاح من 1-3 صباحاً)',
  };
}
