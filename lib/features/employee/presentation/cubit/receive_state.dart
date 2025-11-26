import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';

enum ReceiveStatus { initial, loading, success, failure }

class ReceiveState extends Equatable {
  final ReceiveStatus status;
  final List<ProductModel> products;
  final String? selectedProductId;
  final String? errorMessage;

  const ReceiveState({
    this.status = ReceiveStatus.initial,
    this.products = const [],
    this.selectedProductId,
    this.errorMessage,
  });

  ReceiveState copyWith({
    ReceiveStatus? status,
    List<ProductModel>? products,
    String? selectedProductId,
    String? errorMessage,
  }) {
    return ReceiveState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, selectedProductId, errorMessage];
}
