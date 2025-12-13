import 'package:equatable/equatable.dart';

enum UserRole { admin, employee }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? branchId; // Null for global admin, required for employees
  final List<String> permissions;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.branchId,
    this.permissions = const [],
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, email, role, branchId, permissions, isActive];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'branchId': branchId,
      'permissions': permissions,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
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
