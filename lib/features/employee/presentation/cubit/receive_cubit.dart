import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/employee/presentation/cubit/receive_state.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/repositories/product_repository.dart';
import 'package:hala_bakeries_sales/features/shared/data/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class ReceiveCubit extends Cubit<ReceiveState> {
  final ProductRepository _productRepository;
  final TransactionRepository _transactionRepository;

  ReceiveCubit(this._productRepository, this._transactionRepository) : super(const ReceiveState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ReceiveStatus.loading));
    try {
      final products = await _productRepository.getProducts();
      emit(state.copyWith(status: ReceiveStatus.success, products: products));
    } catch (e) {
      emit(state.copyWith(status: ReceiveStatus.failure, errorMessage: 'فشل تحميل المنتجات'));
    }
  }

  void selectProduct(ProductModel product) {
    emit(state.copyWith(selectedProduct: product));
  }

  Future<void> submitReceive(int quantity, String notes) async {
    if (state.selectedProduct == null) return;

    emit(state.copyWith(status: ReceiveStatus.submitting));
    try {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        productId: state.selectedProduct!.id,
        productName: state.selectedProduct!.name,
        type: TransactionType.receive,
        quantity: quantity,
        date: DateTime.now(),
        notes: notes,
        userId: 'current_user_id', // Should get from Auth
      );

      await _transactionRepository.addTransaction(transaction);
      
      emit(state.copyWith(status: ReceiveStatus.success));
    } catch (e) {
      emit(state.copyWith(status: ReceiveStatus.failure, errorMessage: 'فشل تسجيل الاستلام'));
    }
  }
}
