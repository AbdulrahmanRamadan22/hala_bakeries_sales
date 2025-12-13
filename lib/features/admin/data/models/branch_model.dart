import 'package:equatable/equatable.dart';

class BranchModel extends Equatable {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;
  final bool isActive;

  const BranchModel({
    required this.id,
    required this.name,
    this.location = '',
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, location, createdAt, isActive];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory BranchModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchModel(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
