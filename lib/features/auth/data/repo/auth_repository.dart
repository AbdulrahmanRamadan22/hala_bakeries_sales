import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

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

      final user = UserModel.fromMap(doc.data()!, uid);
      
      // 3. Save User Locally
      await saveUserLocally(user);
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await clearLocalUser();
  }

  Future<UserModel?> getCurrentUser() async {
    // 1. Check Local Storage first
    final localUser = await getUserLocally();
    if (localUser != null) return localUser;

    // 2. Fallback to Firebase (e.g. if cache cleared but still logged in via SDK)
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!, user.uid);
        await saveUserLocally(userModel); // Update local cache
        return userModel;
      }
    } catch (e) {
      // Ignore error, return null
    }
    return null;
  }

  // Local Storage Helpers
  Future<void> saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toMap()));
  }

  Future<UserModel?> getUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userDataString);
        // We need the ID. It should be in the map if toMap includes it, 
        // or we need to handle it. UserModel.toMap usually includes 'id' or we pass it.
        // Let's check UserModel.toMap. If it doesn't have ID, we might have an issue.
        // Assuming toMap has 'id' or we saved it.
        // Actually, fromMap takes (map, id). 
        // If 'id' is in the map, we can extract it.
        final id = userMap['id'] ?? ''; 
        return UserModel.fromMap(userMap, id);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}
