import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<ProductModel> products;
  final Map<String, int> productStocks; // productId -> total stock across all branches
  final Map<String, List<BranchStockDetail>> branchStockDetails; // productId -> list of branch stocks
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.productStocks = const {},
    this.branchStockDetails = const {},
    this.errorMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? products,
    Map<String, int>? productStocks,
    Map<String, List<BranchStockDetail>>? branchStockDetails,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      productStocks: productStocks ?? this.productStocks,
      branchStockDetails: branchStockDetails ?? this.branchStockDetails,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, productStocks, branchStockDetails, errorMessage];
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
