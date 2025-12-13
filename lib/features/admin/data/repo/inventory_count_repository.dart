import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/inventory_count_model.dart';

class InventoryCountRepository {
  final FirebaseFirestore _firestore;

  InventoryCountRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create new inventory count
  Future<void> createInventoryCount(InventoryCountModel count) async {
    try {
      await _firestore
          .collection('inventory_counts')
          .doc(count.id)
          .set(count.toMap());
    } catch (e) {
      throw Exception('فشل في إنشاء الجرد: $e');
    }
  }

  /// Update existing inventory count
  Future<void> updateInventoryCount(InventoryCountModel count) async {
    try {
      await _firestore
          .collection('inventory_counts')
          .doc(count.id)
          .update(count.toMap());
    } catch (e) {
      throw Exception('فشل في تحديث الجرد: $e');
    }
  }

  /// Get inventory count by ID
  Future<InventoryCountModel?> getInventoryCountById(String id) async {
    try {
      final doc = await _firestore
          .collection('inventory_counts')
          .doc(id)
          .get();

      if (!doc.exists) return null;

      return InventoryCountModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('فشل في جلب الجرد: $e');
    }
  }

  /// Get all inventory counts for a branch
  Future<List<InventoryCountModel>> getInventoryCountsByBranch(
    String branchId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_counts')
          .where('branchId', isEqualTo: branchId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InventoryCountModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب جرود الفرع: $e');
    }
  }

  /// Get inventory counts within date range
  Future<List<InventoryCountModel>> getInventoryCountsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      Query query = _firestore.collection('inventory_counts');

      if (branchId != null) {
        query = query.where('branchId', isEqualTo: branchId);
      }

      final snapshot = await query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InventoryCountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب الجرود: $e');
    }
  }

  /// Check if inventory count exists for today
  Future<InventoryCountModel?> getTodayInventoryCount(String branchId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('inventory_counts')
          .where('branchId', isEqualTo: branchId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return InventoryCountModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('فشل في التحقق من الجرد اليومي: $e');
    }
  }

  /// Delete inventory count (Admin only)
  Future<void> deleteInventoryCount(String id) async {
    try {
      await _firestore.collection('inventory_counts').doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف الجرد: $e');
    }
  }

  /// Get all inventory counts (Admin only)
  Future<List<InventoryCountModel>> getAllInventoryCounts({
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_counts')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InventoryCountModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب كل الجرود: $e');
    }
  }

  /// Stream inventory counts for real-time updates
  Stream<List<InventoryCountModel>> streamInventoryCountsByBranch(
    String branchId,
  ) {
    return _firestore
        .collection('inventory_counts')
        .where('branchId', isEqualTo: branchId)
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryCountModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
