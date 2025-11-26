import 'package:equatable/equatable.dart';

class BranchModel extends Equatable {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;

  const BranchModel({
    required this.id,
    required this.name,
    this.location = '',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, location, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BranchModel.fromMap(Map<String, dynamic> map) {
    return BranchModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
