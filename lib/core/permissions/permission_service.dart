import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/core/permissions/permissions.dart';

class PermissionService {
  /// Check if user has a specific permission
  static bool hasPermission(UserModel user, String permission) {
    // Admins have all permissions
    if (user.role == UserRole.admin) {
      return true;
    }

    // Check if employee has the permission
    return user.permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  static bool hasAnyPermission(UserModel user, List<String> permissions) {
    if (user.role == UserRole.admin) {
      return true;
    }

    return permissions.any((permission) => user.permissions.contains(permission));
  }

  /// Check if user has all of the given permissions
  static bool hasAllPermissions(UserModel user, List<String> permissions) {
    if (user.role == UserRole.admin) {
      return true;
    }

    return permissions.every((permission) => user.permissions.contains(permission));
  }

  /// Get all available permissions
  static List<String> getAllPermissions() {
    return AppPermissions.allPermissions;
  }

  /// Get permission display name
  static String getPermissionName(String permission) {
    return AppPermissions.permissionNames[permission] ?? permission;
  }

  /// Get permission description
  static String getPermissionDescription(String permission) {
    return AppPermissions.permissionDescriptions[permission] ?? '';
  }

  /// Check if user can view admin features (read-only access)
  static bool canViewAdminFeatures(UserModel user) {
    if (user.role == UserRole.admin) {
      return true;
    }
    return user.permissions.contains(AppPermissions.canViewAdminFeatures);
  }

  /// Check if user can EDIT admin features (not just view)
  static bool canEditAdminFeatures(UserModel user) {
    // Only admins can edit
    return user.role == UserRole.admin;
  }
}
