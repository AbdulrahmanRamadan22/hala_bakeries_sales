import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

enum DamageStatus { initial, loading, submitting, success, failure, submitted }

class DamageState extends Equatable {
  final DamageStatus status;
  final List<ProductModel> products;
  final Map<String, double> cart; // ProductId -> Quantity
  final String? errorMessage;

  const DamageState({
    this.status = DamageStatus.initial,
    this.products = const [],
    this.cart = const {},
    this.errorMessage,
  });

  DamageState copyWith({
    DamageStatus? status,
    List<ProductModel>? products,
    Map<String, double>? cart,
    String? errorMessage,
  }) {
    return DamageState(
      status: status ?? this.status,
      products: products ?? this.products,
      cart: cart ?? this.cart,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, cart, errorMessage];
}
