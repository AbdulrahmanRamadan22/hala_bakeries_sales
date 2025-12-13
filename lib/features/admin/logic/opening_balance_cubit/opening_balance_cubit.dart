import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hala_bakeries_sales/features/admin/logic/opening_balance_cubit/opening_balance_state.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/repo/branch_stock_repository.dart';
import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class OpeningBalanceCubit extends Cubit<OpeningBalanceState> {
  final BranchRepository _branchRepository;
  final ProductRepository _productRepository;
  final BranchStockRepository _branchStockRepository;
  final TransactionRepository _transactionRepository;

  OpeningBalanceCubit(
    this._branchRepository,
    this._productRepository,
    this._branchStockRepository,
    this._transactionRepository,
  ) : super(const OpeningBalanceState());

  Future<void> loadInitialData() async {
    emit(state.copyWith(status: OpeningBalanceStatus.loading));
    try {
      final branches = await _branchRepository.getBranches();
      emit(state.copyWith(
        status: OpeningBalanceStatus.success,
        branches: branches,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OpeningBalanceStatus.failure,
        errorMessage: 'فشل تحميل البيانات',
      ));
    }
  }

  Future<void> selectBranch(BranchModel branch) async {
    emit(state.copyWith(status: OpeningBalanceStatus.loading));
    try {
      // Load all products
      final products = await _productRepository.getProducts();
      
      // Load existing stock for this branch
      final branchStocks = await _branchStockRepository.getBranchStocks(branch.id);
      
      // Create product entries
      final entries = products.map((product) {
        // Find existing stock for this product
        final existingStock = branchStocks.where((stock) => stock.productId == product.id).firstOrNull;
        
        return ProductStockEntry(
          product: product,
          quantity: existingStock?.currentStock ?? 0,
          hasOpeningBalance: existingStock?.hasOpeningBalance ?? false,
        );
      }).toList();

      emit(state.copyWith(
        status: OpeningBalanceStatus.success,
        selectedBranch: branch,
        productEntries: entries,
      ));
    } catch (e) {
      print('Error in selectBranch: $e');
      emit(state.copyWith(
        status: OpeningBalanceStatus.failure,
        errorMessage: 'فشل تحميل المنتجات: ${e.toString()}',
      ));
    }
  }

  void updateProductQuantity(String productId, int quantity) {
    final updatedEntries = state.productEntries.map((entry) {
      if (entry.product.id == productId) {
        return entry.copyWith(quantity: quantity);
      }
      return entry;
    }).toList();

    emit(state.copyWith(productEntries: updatedEntries));
  }

  Future<void> saveOpeningBalances() async {
    if (state.selectedBranch == null) {
      emit(state.copyWith(
        errorMessage: 'يرجى اختيار فرع أولاً',
      ));
      return;
    }

    emit(state.copyWith(isSaving: true));
    
    try {
      final branchId = state.selectedBranch!.id;
      
      // Save opening balance for each product with quantity > 0
      for (final entry in state.productEntries) {
        if (entry.quantity > 0 && !entry.hasOpeningBalance) {
          // Set opening balance in branch_stock
          await _branchStockRepository.setOpeningBalance(
            branchId: branchId,
            productId: entry.product.id,
            quantity: entry.quantity,
          );

          // Create opening balance transaction
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            type: TransactionType.openingBalance,
            productId: entry.product.id,
            branchId: branchId,
            userId: 'admin', // Admin user
            quantity: entry.quantity.toDouble(),
            beforeStock: 0,
            afterStock: entry.quantity.toDouble(),
            timestamp: DateTime.now(),
            notes: 'رصيد افتتاحي',
          );

          await _transactionRepository.addTransaction(transaction);
        }
      }

      emit(state.copyWith(
        isSaving: false,
        status: OpeningBalanceStatus.success,
        successMessage: 'تم حفظ الرصيد الافتتاحي بنجاح',
      ));

      // Reload data to reflect changes
      if (state.selectedBranch != null) {
        await selectBranch(state.selectedBranch!);
      }
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        status: OpeningBalanceStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
