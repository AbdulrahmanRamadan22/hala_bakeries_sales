# نشر Cloud Functions

## المتطلبات

1. حساب Firebase مع تفعيل Blaze Plan (الخطة المدفوعة)
2. Node.js 18 مثبت على جهازك
3. Firebase CLI مثبت

## خطوات النشر

### 1. تسجيل الدخول إلى Firebase

```bash
firebase login
```

### 2. التأكد من ربط المشروع

```bash
firebase use --add
```

اختر مشروع Firebase الخاص بك.

### 3. نشر Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 4. التحقق من النشر

بعد النشر الناجح، ستظهر رسالة مثل:

```
✔  functions[createEmployee(us-central1)] Successful create operation.
✔  functions[updateEmployeePassword(us-central1)] Successful create operation.
✔  functions[deleteEmployee(us-central1)] Successful create operation.
```

### 5. اختبار Cloud Functions

يمكنك اختبار Functions من Firebase Console:
1. افتح Firebase Console
2. اذهب إلى Functions
3. اختر Function واضغط على "Logs" لرؤية السجلات

---

## استخدام Functions في التطبيق

### إنشاء موظف جديد

```dart
await employeeRepository.addEmployee(
  name: 'أحمد محمد',
  email: 'ahmad@example.com',
  password: 'password123',
  phone: '01012345678',
  branchId: 'branch_id_here',
);
```

### تحديث كلمة المرور

```dart
await employeeRepository.updateEmployeePassword(
  employeeId: 'employee_uid',
  newPassword: 'newpassword123',
);
```

### حذف موظف

```dart
await employeeRepository.deleteEmployee('employee_uid');
```

---

## التكلفة

مع الخطة المجانية (Blaze Plan):
- 2 مليون استدعاء/شهر مجاناً
- 400,000 GB-ثانية مجاناً
- 200,000 CPU-ثانية مجاناً

**التكلفة المتوقعة**: $0/شهر (ضمن الحد المجاني)

---

## استكشاف الأخطاء

### خطأ: "unauthenticated"
- تأكد من تسجيل دخول المستخدم
- تحقق من صلاحيات Firebase Authentication

### خطأ: "permission-denied"
- تأكد من أن المستخدم أدمن
- تحقق من حقل `role` في Firestore

### خطأ: "already-exists"
- البريد الإلكتروني مستخدم بالفعل
- استخدم بريد إلكتروني مختلف

---

## ملاحظات مهمة

⚠️ **تحذير**: Cloud Functions تتطلب Blaze Plan (خطة مدفوعة)
- يمكنك البدء بالخطة المجانية ضمن الحدود المذكورة
- لن يتم محاسبتك إلا إذا تجاوزت الحد المجاني

✅ **الأمان**: 
- جميع Functions محمية بالتحقق من صلاحيات الأدمن
- كلمات المرور مشفرة عبر HTTPS
- لا يتم حفظ كلمات المرور في Firestore
