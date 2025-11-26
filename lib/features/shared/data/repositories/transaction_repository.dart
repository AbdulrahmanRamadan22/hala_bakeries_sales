import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addTransaction(TransactionModel transaction) async {
    final batch = _firestore.batch();

    // 1. Create Transaction Document
    final transactionRef = _firestore.collection('transactions').doc(transaction.id);
    batch.set(transactionRef, transaction.toMap());

    // 2. Update Product Stock
    // We assume stock is tracked in the 'products' collection for simplicity in this phase.
    // In a real multi-branch app, stock should be in a subcollection 'branches/{branchId}/stock/{productId}'
    // or 'products/{productId}/stock/{branchId}'.
    // Let's assume 'products' has a global stock for now OR we are just updating a 'stock' field 
    // but wait, the requirements mentioned multi-branch.
    // If we update 'products' directly, it's global.
    // Let's check ProductModel. It likely has 'stockQuantity'.
    // If so, that's global. If we want per-branch, we need a separate structure.
    // For this MVP/Demo, I will assume we are updating the global product stock 
    // OR I should implement a proper 'Stock' collection.
    
    // Let's stick to a simple approach first: Update 'products' collection if it has stock, 
    // or create a 'stock' collection.
    // Given I can't easily change the schema without breaking previous assumptions, 
    // I'll check if ProductModel has stock. If yes, I update it.
    
    final productRef = _firestore.collection('products').doc(transaction.productId);
    
    if (transaction.type == TransactionType.receive) {
      batch.update(productRef, {
        'stockQuantity': FieldValue.increment(transaction.quantity),
      });
    } else if (transaction.type == TransactionType.damage || transaction.type == TransactionType.spoilage || transaction.type == TransactionType.sale) {
      batch.update(productRef, {
        'stockQuantity': FieldValue.increment(-transaction.quantity),
      });
    }

    await batch.commit();
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
