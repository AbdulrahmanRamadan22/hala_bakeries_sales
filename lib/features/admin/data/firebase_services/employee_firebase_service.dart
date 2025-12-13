import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';

class EmployeeFirebaseService {
  // No longer using Cloud Functions
  EmployeeFirebaseService();

  /// إنشاء حساب مستخدم جديد (موظف أو أدمن) باستخدام Secondary App
  /// هذا يسمح بإنشاء مستخدم جديد دون تسجيل خروج الأدمن
  Future<String> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? branchId, // Optional for admins
    UserRole role = UserRole.employee, // Default to employee
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. تهيئة تطبيق Firebase ثانوي
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. الحصول على instance من Auth للتطبيق الثانوي
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 3. إنشاء المستخدم
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 4. حفظ بيانات المستخدم في Firestore (باستخدام التطبيق الرئيسي)
      // نستخدم التطبيق الرئيسي لأن الأدمن هو من يملك صلاحية الكتابة
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name, // Use the passed role (admin or employee)
        'branchId': branchId, // Null for admins
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'isActive': true, // علامة لتفعيل الحساب
      });

      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicErrorMessage(e.code, e.message));
    } catch (e) {
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    } finally {
      // 5. حذف التطبيق الثانوي لتنظيف الموارد
      await secondaryApp?.delete();
    }
  }

  /// إرسال بريد إعادة تعيين كلمة المرور
  /// (لا يمكن تغيير كلمة المرور مباشرة لمستخدم آخر من Client SDK)
  Future<void> updateEmployeePassword({
    required String email,
  }) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicErrorMessage(e.code, e.message));
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  /// حذف حساب موظف (Soft Delete)
  /// نقوم بحذف بياناته من Firestore، مما يمنعه من الدخول إذا كانت قواعد الأمان تتحقق من وجود المستند
  Future<void> deleteEmployeeAccount(String employeeId) async {
    try {
      // Soft Delete: Update isActive to false instead of deleting
      // This preserves history but prevents the user from logging in (if rules check isActive)
      await FirebaseFirestore.instance.collection('users').doc(employeeId).update({'isActive': false});
    } catch (e) {
      throw Exception('خطأ في حذف البيانات: ${e.toString()}');
    }
  }

  /// ترجمة رسائل الخطأ إلى العربية
  String _getArabicErrorMessage(String code, String? message) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-not-found':
        return 'المستخدم غير موجود';
      default:
        return message ?? 'حدث خطأ غير متوقع';
    }
  }
}
