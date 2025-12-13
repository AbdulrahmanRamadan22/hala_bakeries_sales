import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart';
import 'package:hala_bakeries_sales/features/admin/data/firebase_services/employee_firebase_service.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore;
  final EmployeeFirebaseService? _employeeService;

  EmployeeRepository({
    FirebaseFirestore? firestore,
    EmployeeFirebaseService? employeeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _employeeService = employeeService;

  Future<List<UserModel>> getEmployees() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('فشل في جلب الموظفين: $e');
    }
  }

  /// إضافة موظف جديد مع إنشاء حساب Firebase Authentication
  Future<void> addEmployee({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String branchId,
  }) async {
    try {
      if (_employeeService == null) {
        throw Exception('خدمة الموظفين غير متوفرة');
      }

      // استدعاء الخدمة لإنشاء الحساب
      await _employeeService!.createEmployeeAccount(
        email: email,
        password: password,
        name: name,
        phone: phone,
        branchId: branchId,
      );
    } catch (e) {
      throw Exception('فشل في إضافة الموظف: ${e.toString()}');
    }
  }

  /// إرسال بريد إعادة تعيين كلمة المرور
  Future<void> updateEmployeePassword({
    required String email,
  }) async {
    try {
      if (_employeeService == null) {
        throw Exception('خدمة الموظفين غير متوفرة');
      }

      await _employeeService!.updateEmployeePassword(
        email: email,
      );
    } catch (e) {
      throw Exception('فشل في إرسال بريد إعادة تعيين كلمة المرور: ${e.toString()}');
    }
  }

  /// حذف موظف (Soft Delete)
  Future<void> deleteEmployee(String id) async {
    try {
      if (_employeeService == null) {
        throw Exception('خدمة الموظفين غير متوفرة');
      }

      await _employeeService!.deleteEmployeeAccount(id);
    } catch (e) {
      throw Exception('فشل في حذف الموظف: ${e.toString()}');
    }
  }

  /// تحديث بيانات موظف (الفرع والصلاحيات)
  Future<void> updateEmployee({
    required String id,
    required String branchId,
    required List<String> permissions,
  }) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'branchId': branchId,
        'permissions': permissions,
      });
    } catch (e) {
      throw Exception('فشل في تحديث بيانات الموظف: $e');
    }
  }
}
