import 'package:equatable/equatable.dart';

enum UserRole { admin, employee }

class UserModel extends Equatable {
  final String id;
  final String username;
  final UserRole role;
  final String? branchId; // Null for global admin, required for employees
  final List<String> permissions;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.branchId,
    this.permissions = const [],
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, username, role, branchId, permissions, isActive];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role.name,
      'branchId': branchId,
      'permissions': permissions,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.employee,
      ),
      branchId: map['branchId'],
      permissions: List<String>.from(map['permissions'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
}
