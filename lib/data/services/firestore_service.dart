import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo user document nếu chưa tồn tại
  Future<void> createUserIfNotExists(
    String uid,
    String name,
    String email,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(' Đã tạo user document mới');
      }
    } catch (e) {
      print('Lỗi createUserIfNotExists: $e');
      rethrow;
    }
  }

  /// Lưu user
  Future<void> saveUser(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true để không ghi đè nếu đã có
      print(' Đã lưu user vào Firestore');
    } catch (e) {
      print('Lỗi saveUser: $e');
      rethrow;
    }
  }

  /// Log activity
  Future<void> logActivity(String uid, String action) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add({'action': action, 'timestamp': FieldValue.serverTimestamp()});
      print('Đã log activity: $action');
    } catch (e) {
      print('Lỗi logActivity: $e');
      rethrow;
    }
  }
}
