import 'package:equatable/equatable.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

enum StockStatus { initial, loading, success, failure }

class StockItem extends Equatable {
  final ProductModel product;
  final double quantity;
  final double openingBalance;
  final DateTime lastUpdated;

  const StockItem({
    required this.product,
    required this.quantity,
    required this.openingBalance,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [product, quantity, openingBalance, lastUpdated];
}

class StockState extends Equatable {
  final StockStatus status;
  final List<StockItem> stockItems;
  final String? errorMessage;

  const StockState({
    this.status = StockStatus.initial,
    this.stockItems = const [],
    this.errorMessage,
  });

  StockState copyWith({
    StockStatus? status,
    List<StockItem>? stockItems,
    String? errorMessage,
  }) {
    return StockState(
      status: status ?? this.status,
      stockItems: stockItems ?? this.stockItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stockItems, errorMessage];
}
