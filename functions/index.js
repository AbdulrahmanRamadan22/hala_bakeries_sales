const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function لإنشاء حساب موظف جديد
 * يتم استدعاؤه من تطبيق الأدمن
 */
exports.createEmployee = functions.https.onCall(async (data, context) => {
    // التحقق من أن المستخدم مسجل دخول
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'يجب تسجيل الدخول أولاً'
        );
    }

    // التحقق من أن المستخدم أدمن
    try {
        const callerDoc = await admin
            .firestore()
            .collection('users')
            .doc(context.auth.uid)
            .get();

        if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
            throw new functions.https.HttpsError(
                'permission-denied',
                'غير مصرح لك بإنشاء حسابات'
            );
        }
    } catch (error) {
        throw new functions.https.HttpsError(
            'internal',
            'خطأ في التحقق من الصلاحيات'
        );
    }

    // استخراج البيانات
    const { email, password, name, phone, branchId } = data;

    // التحقق من البيانات المطلوبة
    if (!email || !password || !name || !branchId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'البيانات المطلوبة غير مكتملة'
        );
    }

    // التحقق من قوة كلمة المرور
    if (password.length < 6) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
        );
    }

    try {
        // إنشاء حساب Firebase Authentication
        const userRecord = await admin.auth().createUser({
            email: email,
            password: password,
            displayName: name,
        });

        // إنشاء مستند في Firestore
        await admin
            .firestore()
            .collection('users')
            .doc(userRecord.uid)
            .set({
                name: name,
                email: email,
                phone: phone || '',
                role: 'employee',
                branchId: branchId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                createdBy: context.auth.uid,
            });

        return {
            success: true,
            uid: userRecord.uid,
            message: 'تم إنشاء حساب الموظف بنجاح',
        };
    } catch (error) {
        // حذف حساب Auth إذا فشل إنشاء Firestore
        if (error.code === 'auth/email-already-exists') {
            throw new functions.https.HttpsError(
                'already-exists',
                'البريد الإلكتروني مستخدم بالفعل'
            );
        }

        throw new functions.https.HttpsError(
            'internal',
            `خطأ في إنشاء الحساب: ${error.message}`
        );
    }
});

/**
 * Cloud Function لتحديث كلمة مرور موظف
 */
exports.updateEmployeePassword = functions.https.onCall(async (data, context) => {
    // التحقق من أن المستخدم مسجل دخول
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'يجب تسجيل الدخول أولاً'
        );
    }

    // التحقق من أن المستخدم أدمن
    try {
        const callerDoc = await admin
            .firestore()
            .collection('users')
            .doc(context.auth.uid)
            .get();

        if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
            throw new functions.https.HttpsError(
                'permission-denied',
                'غير مصرح لك بتحديث كلمات المرور'
            );
        }
    } catch (error) {
        throw new functions.https.HttpsError(
            'internal',
            'خطأ في التحقق من الصلاحيات'
        );
    }

    const { employeeId, newPassword } = data;

    // التحقق من البيانات
    if (!employeeId || !newPassword) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'البيانات المطلوبة غير مكتملة'
        );
    }

    if (newPassword.length < 6) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
        );
    }

    try {
        // تحديث كلمة المرور
        await admin.auth().updateUser(employeeId, {
            password: newPassword,
        });

        return {
            success: true,
            message: 'تم تحديث كلمة المرور بنجاح',
        };
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError(
                'not-found',
                'الموظف غير موجود'
            );
        }

        throw new functions.https.HttpsError(
            'internal',
            `خطأ في تحديث كلمة المرور: ${error.message}`
        );
    }
});

/**
 * Cloud Function لحذف حساب موظف
 */
exports.deleteEmployee = functions.https.onCall(async (data, context) => {
    // التحقق من أن المستخدم مسجل دخول
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'يجب تسجيل الدخول أولاً'
        );
    }

    // التحقق من أن المستخدم أدمن
    try {
        const callerDoc = await admin
            .firestore()
            .collection('users')
            .doc(context.auth.uid)
            .get();

        if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
            throw new functions.https.HttpsError(
                'permission-denied',
                'غير مصرح لك بحذف الحسابات'
            );
        }
    } catch (error) {
        throw new functions.https.HttpsError(
            'internal',
            'خطأ في التحقق من الصلاحيات'
        );
    }

    const { employeeId } = data;

    if (!employeeId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'معرف الموظف مطلوب'
        );
    }

    try {
        // حذف من Authentication
        await admin.auth().deleteUser(employeeId);

        // حذف من Firestore
        await admin
            .firestore()
            .collection('users')
            .doc(employeeId)
            .delete();

        return {
            success: true,
            message: 'تم حذف حساب الموظف بنجاح',
        };
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError(
                'not-found',
                'الموظف غير موجود'
            );
        }

        throw new functions.https.HttpsError(
            'internal',
            `خطأ في حذف الحساب: ${error.message}`
        );
    }
});
