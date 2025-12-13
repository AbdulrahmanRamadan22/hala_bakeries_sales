import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

enum ReceiveStatus { initial, loading, submitting, success, failure, submitted }

class ReceiveState extends Equatable {
  final ReceiveStatus status;
  final List<ProductModel> products;
  final Map<String, double> cart; // ProductId -> Quantity
  final String? errorMessage;

  const ReceiveState({
    this.status = ReceiveStatus.initial,
    this.products = const [],
    this.cart = const {},
    this.errorMessage,
  });

  ReceiveState copyWith({
    ReceiveStatus? status,
    List<ProductModel>? products,
    Map<String, double>? cart,
    String? errorMessage,
  }) {
    return ReceiveState(
      status: status ?? this.status,
      products: products ?? this.products,
      cart: cart ?? this.cart,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, cart, errorMessage];
}
