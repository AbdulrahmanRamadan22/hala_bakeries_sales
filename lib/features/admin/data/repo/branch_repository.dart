import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart';

class BranchRepository {
  final FirebaseFirestore _firestore;

  BranchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<BranchModel>> getBranches() async {
    try {
      final snapshot = await _firestore
          .collection('branches')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BranchModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch branches: $e');
    }
  }

  Future<void> addBranch(BranchModel branch) async {
    try {
      await _firestore.collection('branches').doc(branch.id).set(branch.toMap());
    } catch (e) {
      throw Exception('Failed to add branch: $e');
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      // Soft Delete
      await _firestore.collection('branches').doc(id).update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete branch: $e');
    }
  }
  Future<void> updateBranch(BranchModel branch) async {
    try {
      await _firestore.collection('branches').doc(branch.id).update(branch.toMap());
    } catch (e) {
      throw Exception('Failed to update branch: $e');
    }
  }

  Future<BranchModel?> getBranch(String id) async {
    try {
      final doc = await _firestore.collection('branches').doc(id).get();
      if (doc.exists) {
        return BranchModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
