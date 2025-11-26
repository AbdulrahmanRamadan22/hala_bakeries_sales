import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';

enum DamageStatus { initial, loading, success, failure }
enum DamageType { damage, spoilage }

class DamageState extends Equatable {
  final DamageStatus status;
  final List<ProductModel> products;
  final String? selectedProductId;
  final DamageType type;
  final String? errorMessage;

  const DamageState({
    this.status = DamageStatus.initial,
    this.products = const [],
    this.selectedProductId,
    this.type = DamageType.damage,
    this.errorMessage,
  });

  DamageState copyWith({
    DamageStatus? status,
    List<ProductModel>? products,
    String? selectedProductId,
    DamageType? type,
    String? errorMessage,
  }) {
    return DamageState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      type: type ?? this.type,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, selectedProductId, type, errorMessage];
}
