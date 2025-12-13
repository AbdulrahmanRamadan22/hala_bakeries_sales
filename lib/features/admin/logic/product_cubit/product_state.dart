import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<ProductModel> products;
  final Map<String, int> productStocks; // productId -> total stock across all branches
  final Map<String, List<BranchStockDetail>> branchStockDetails; // productId -> list of branch stocks
  final String? errorMessage;
  final String? loadingMessage; // Message to show during loading

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.productStocks = const {},
    this.branchStockDetails = const {},
    this.errorMessage,
    this.loadingMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? products,
    Map<String, int>? productStocks,
    Map<String, List<BranchStockDetail>>? branchStockDetails,
    String? errorMessage,
    String? loadingMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      productStocks: productStocks ?? this.productStocks,
      branchStockDetails: branchStockDetails ?? this.branchStockDetails,
      errorMessage: errorMessage ?? this.errorMessage,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, productStocks, branchStockDetails, errorMessage, loadingMessage];
}

class BranchStockDetail {
  final String branchId;
  final String branchName;
  final int stock;

  BranchStockDetail({
    required this.branchId,
    required this.branchName,
    required this.stock,
  });
}
