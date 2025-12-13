import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final String category;
  final String unit; // e.g., 'kg', 'piece'
  final double price;
  final int stockQuantity;
  final int minStockLevel;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.unit,
    this.price = 0.0,
    this.stockQuantity = 0,
    this.minStockLevel = 5,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, barcode, category, unit, price, stockQuantity, minStockLevel, isActive];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'price': price,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'isActive': isActive,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      category: map['category'] ?? '',
      unit: map['unit'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stockQuantity: (map['stockQuantity'] as num? ?? 0).toInt(),
      minStockLevel: (map['minStockLevel'] as num? ?? 5).toInt(),
      isActive: map['isActive'] ?? true,
    );
  }
}
