import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hala_bakeries_sales/features/shared/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserModel> login(String email, String password) async {
    try {
      // 1. Authenticate with Firebase Auth
      // Note: We are using email for auth, but the UI asks for username.
      // In a real app, we'd either force email or look up email by username first.
      // For simplicity here, we assume the username IS the email or we append a domain.
      // Let's assume username is email for now to make it work with standard Firebase Auth.
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Fetch User Data from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromMap(doc.data()!, uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }
    } catch (e) {
      // Ignore error, return null
    }
    return null;
  }
}
