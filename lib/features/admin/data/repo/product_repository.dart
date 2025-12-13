import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts() async {
    try {
      print('ProductRepository: Fetching products from Firestore...');
      // Filter by isActive = true
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      
      print('ProductRepository: Received ${snapshot.docs.length} active documents');
      
      if (snapshot.docs.isEmpty) {
        print('ProductRepository: WARNING - No active products found in Firestore!');
        return [];
      }
      
      final products = <ProductModel>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final product = ProductModel.fromMap(data, doc.id);
          products.add(product);
        } catch (e) {
          print('ProductRepository: ERROR parsing document ${doc.id}: $e');
        }
      }
      
      print('ProductRepository: Successfully loaded ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      print('ProductRepository ERROR: $e');
      print('StackTrace: $stackTrace');
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

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Soft Delete: Update isActive to false instead of deleting
      await _firestore.collection('products').doc(id).update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Check if a barcode already exists for another product
  /// Returns true if barcode exists, false otherwise
  /// [excludeProductId] is used when editing to exclude the current product
  Future<bool> checkBarcodeExists(String barcode, {String? excludeProductId}) async {
    try {
      if (barcode.isEmpty) return false;
      
      final snapshot = await _firestore
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (snapshot.docs.isEmpty) return false;
      
      // If we're editing, check if the barcode belongs to a different product
      if (excludeProductId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeProductId);
      }
      
      return true;
    } catch (e) {
      print('ProductRepository: Error checking barcode: $e');
      return false;
    }
  }
}
