import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/branch_model.dart';

class BranchRepository {
  final FirebaseFirestore _firestore;

  BranchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<BranchModel>> getBranches() async {
    try {
      final snapshot = await _firestore.collection('branches').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure ID is passed if not in data, though typically we store it in data too or use doc.id
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
      await _firestore.collection('branches').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete branch: $e');
    }
  }
}
