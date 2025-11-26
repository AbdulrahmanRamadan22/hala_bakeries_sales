import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).set(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
