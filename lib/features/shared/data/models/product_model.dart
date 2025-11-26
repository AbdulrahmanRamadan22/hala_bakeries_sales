import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final String category;
  final String unit; // e.g., 'kg', 'piece'
  final double price;
  final int stockQuantity;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.unit,
    this.price = 0.0,
    this.stockQuantity = 0,
  });

  @override
  List<Object?> get props => [id, name, barcode, category, unit, price, stockQuantity];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'price': price,
      'stockQuantity': stockQuantity,
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
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }
}
