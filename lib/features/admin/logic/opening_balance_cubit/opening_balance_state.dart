import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';

enum OpeningBalanceStatus { initial, loading, success, failure }

class ProductStockEntry {
  final ProductModel product;
  final int quantity;
  final bool hasOpeningBalance;

  ProductStockEntry({
    required this.product,
    this.quantity = 0,
    this.hasOpeningBalance = false,
  });

  ProductStockEntry copyWith({
    ProductModel? product,
    int? quantity,
    bool? hasOpeningBalance,
  }) {
    return ProductStockEntry(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      hasOpeningBalance: hasOpeningBalance ?? this.hasOpeningBalance,
    );
  }
}

class OpeningBalanceState extends Equatable {
  final OpeningBalanceStatus status;
  final List<BranchModel> branches;
  final List<ProductStockEntry> productEntries;
  final BranchModel? selectedBranch;
  final String? errorMessage;
  final String? successMessage;
  final bool isSaving;

  const OpeningBalanceState({
    this.status = OpeningBalanceStatus.initial,
    this.branches = const [],
    this.productEntries = const [],
    this.selectedBranch,
    this.errorMessage,
    this.successMessage,
    this.isSaving = false,
  });

  OpeningBalanceState copyWith({
    OpeningBalanceStatus? status,
    List<BranchModel>? branches,
    List<ProductStockEntry>? productEntries,
    BranchModel? selectedBranch,
    String? errorMessage,
    String? successMessage,
    bool? isSaving,
  }) {
    return OpeningBalanceState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      productEntries: productEntries ?? this.productEntries,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage, // Don't keep old message by default to allow clearing
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
        status,
        branches,
        productEntries,
        selectedBranch,
        errorMessage,
        successMessage,
        isSaving,
      ];
}
