import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addTransaction(TransactionModel transaction) async {
    // 1. Create Transaction Document
    // If ID is empty, generate one or let Firestore generate it
    final docRef = transaction.id.isEmpty 
        ? _firestore.collection('transactions').doc() 
        : _firestore.collection('transactions').doc(transaction.id);
        
    final transactionToSave = transaction.id.isEmpty
        ? transaction.copyWith(id: docRef.id)
        : transaction;

    await docRef.set(transactionToSave.toMap());
    
    // Note: Stock updates are now handled by BranchStockRepository
    // so we don't update the 'products' collection here anymore.
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<List<TransactionModel>> getTransactionsByEmployee(String employeeId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: employeeId)
          .get();
      
      final transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions;
    } catch (e) {
      print('Error fetching employee transactions: $e');
      throw Exception('Failed to fetch employee transactions: $e');
    }
  }
}
