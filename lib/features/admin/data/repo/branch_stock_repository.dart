import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_stock_model.dart';

class BranchStockRepository {
  final FirebaseFirestore _firestore;

  BranchStockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper to generate document ID
  String generateId(String branchId, String productId) {
    return '${branchId}_$productId';
  }

  /// Get stock for a specific product in a specific branch
  Future<BranchStockModel?> getBranchStock(
      String branchId, String productId) async {
    try {
      final id = generateId(branchId, productId);
      final doc = await _firestore.collection('branch_stock').doc(id).get();
      
      if (doc.exists) {
        return BranchStockModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch branch stock: $e');
    }
  }

  /// Get all stock for a specific branch
  Future<List<BranchStockModel>> getBranchStocks(String branchId) async {
    try {
      final snapshot = await _firestore
          .collection('branch_stock')
          .where('branchId', isEqualTo: branchId)
          .get();

      return snapshot.docs
          .map((doc) => BranchStockModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch branch stocks: $e');
    }
  }

  /// Get all stock for a specific product across all branches
  Future<List<BranchStockModel>> getProductStocks(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('branch_stock')
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs
          .map((doc) => BranchStockModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch product stocks: $e');
    }
  }

  /// Set or update branch stock
  Future<void> setBranchStock(BranchStockModel stock) async {
    try {
      await _firestore
          .collection('branch_stock')
          .doc(stock.id)
          .set(stock.toMap());
    } catch (e) {
      throw Exception('Failed to set branch stock: $e');
    }
  }

  /// Update stock quantity for a branch-product combination
  Future<void> updateStock({
    required String branchId,
    required String productId,
    required int quantity,
    required bool isAddition, // true for receive, false for damage
  }) async {
    try {
      final id = generateId(branchId, productId);
      final docRef = _firestore.collection('branch_stock').doc(id);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create new stock entry if doesn't exist
          final newStock = BranchStockModel(
            id: id,
            branchId: branchId,
            productId: productId,
            currentStock: isAddition ? quantity : 0,
            hasOpeningBalance: false,
            lastUpdated: DateTime.now(),
          );
          transaction.set(docRef, newStock.toMap());
        } else {
          // Update existing stock
          final currentStock = BranchStockModel.fromMap(doc.data()!, doc.id);
          final newQuantity = isAddition
              ? currentStock.currentStock + quantity
              : currentStock.currentStock - quantity;

          if (newQuantity < 0) {
            throw Exception('المخزون غير كافٍ');
          }

          transaction.update(docRef, {
            'currentStock': newQuantity,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Set opening balance for a product in a branch
  /// This should only be done once per product per branch
  Future<void> setOpeningBalance({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final docId = generateId(branchId, productId);
      final docRef = _firestore.collection('branch_stock').doc(docId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['hasOpeningBalance'] == true) {
             // Already has opening balance, just return to avoid error
             // or we could update it if that's desired behavior
             return;
          }
          
          // Update existing stock (add opening balance to current stock)
          final currentStock = (data['currentStock'] as num).toInt();
          transaction.update(docRef, {
            'currentStock': currentStock + quantity,
            'hasOpeningBalance': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new stock entry
          final newStock = BranchStockModel(
            id: docId,
            branchId: branchId,
            productId: productId,
            currentStock: quantity,
            hasOpeningBalance: true,
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(docRef, newStock.toMap());
        }
      });
    } catch (e) {
      throw Exception('Failed to set opening balance: $e');
    }
  }

  Future<int> getTotalProductStock(String productId) async {
    try {
      final stocks = await getProductStocks(productId);
      return stocks.fold<int>(0, (sum, stock) => sum + stock.currentStock);
    } catch (e) {
      throw Exception('Failed to get total product stock: $e');
    }
  }
}
