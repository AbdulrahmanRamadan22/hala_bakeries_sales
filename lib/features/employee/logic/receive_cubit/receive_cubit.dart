import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/employee/logic/receive_cubit/receive_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class ReceiveCubit extends Cubit<ReceiveState> {
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final TransactionRepository _transactionRepository;
  final String branchId;
  final String userId;

  ReceiveCubit(
    this._productRepository,
    this._branchStockRepository,
    this._transactionRepository,
    this.branchId,
    this.userId,
  ) : super(const ReceiveState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ReceiveStatus.loading));
    try {
      final products = await _productRepository.getProducts();
      emit(state.copyWith(status: ReceiveStatus.success, products: products));
    } catch (e) {
      emit(state.copyWith(status: ReceiveStatus.failure, errorMessage: 'فشل تحميل المنتجات'));
    }
  }

  void addToCart(String productId, double quantity) {
    final newCart = Map<String, double>.from(state.cart);
    if (newCart.containsKey(productId)) {
      newCart[productId] = newCart[productId]! + quantity;
    } else {
      newCart[productId] = quantity;
    }
    emit(state.copyWith(cart: newCart));
  }

  void updateCartQuantity(String productId, double quantity) {
    final newCart = Map<String, double>.from(state.cart);
    if (quantity <= 0) {
      newCart.remove(productId);
    } else {
      newCart[productId] = quantity;
    }
    emit(state.copyWith(cart: newCart));
  }

  void removeFromCart(String productId) {
    final newCart = Map<String, double>.from(state.cart);
    newCart.remove(productId);
    emit(state.copyWith(cart: newCart));
  }

  void clearCart() {
    emit(state.copyWith(cart: {}));
  }

  Future<void> submitBatch(String notes) async {
    if (state.cart.isEmpty) return;

    emit(state.copyWith(status: ReceiveStatus.submitting));
    try {
      // Create transactions for all items in cart
      for (final entry in state.cart.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        
        // Get current stock from branch_stock
        final branchStock = await _branchStockRepository.getBranchStock(branchId, productId);
        final beforeStock = branchStock?.currentStock ?? 0;
        final afterStock = beforeStock + quantity.toInt();

        final transaction = TransactionModel(
          id: const Uuid().v4(),
          productId: productId,
          branchId: branchId,
          type: TransactionType.receive,
          quantity: quantity,
          timestamp: DateTime.now(),
          notes: notes,
          userId: userId,
          beforeStock: beforeStock.toDouble(),
          afterStock: afterStock.toDouble(),
        );

        // Update branch stock
        await _branchStockRepository.updateStock(
          branchId: branchId,
          productId: productId,
          quantity: quantity.toInt(),
          isAddition: true,
        );

        // Record transaction
        await _transactionRepository.addTransaction(transaction);
      }
      
      emit(state.copyWith(status: ReceiveStatus.submitted, cart: {}));
    } catch (e) {
      emit(state.copyWith(
        status: ReceiveStatus.failure,
        errorMessage: e.toString().contains('المخزون') ? e.toString() : 'فشل تسجيل الاستلام',
      ));
    }
  }
}
