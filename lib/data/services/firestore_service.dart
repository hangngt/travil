import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // USER MANAGEMENT

  /// Tạo user document nếu chưa tồn tại
  Future<void> createUserIfNotExists(
    String uid,
    String name,
    String email,
  ) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
        print(' Created new user document for $uid');
      }
    } catch (e) {
      print(' createUserIfNotExists error: $e');
      rethrow;
    }
  }

  // WILL GO COLLECTION

  /// Thêm sản phẩm vào danh sách Will Go
  Future<void> addToWillGo(
    String uid,
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('willgo')
          .doc(productId)
          .set({
            ...productData,
            'addedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print(' Added to Will Go: $productId');
    } catch (e) {
      print(' addToWillGo error: $e');
      rethrow;
    }
  }

  /// Xóa khỏi Will Go
  Future<void> removeFromWillGo(String uid, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('willgo')
          .doc(productId)
          .delete();

      print(' Removed from Will Go: $productId');
    } catch (e) {
      print(' removeFromWillGo error: $e');
    }
  }

  /// Lấy danh sách Will Go của user
  Future<List<Map<String, dynamic>>> getWillGoList(String uid) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('willgo')
              .orderBy('addedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print(' getWillGoList error: $e');
      return [];
    }
  }

  /// Stream Will Go (realtime)
  Stream<List<Map<String, dynamic>>> getWillGoStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('willgo')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // RATING COLLECTION

  /// Thêm / Cập nhật rating cho product
  Future<void> addRating({
    required String uid,
    required String productId,
    required double rating,
    String? review,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('ratings')
          .doc(productId)
          .set({
            'productId': productId,
            'rating': rating,
            'review': review,
            'ratedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Cũng lưu rating vào collection interactions (dùng cho recommendation)
      await _firestore.collection('interactions').add({
        'user_id': uid,
        'product_id': productId,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print(' Rated product $productId with $rating stars');
    } catch (e) {
      print(' addRating error: $e');
      rethrow;
    }
  }

  /// Lấy rating của user cho 1 product
  Future<double?> getUserRating(String uid, String productId) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('ratings')
              .doc(productId)
              .get();

      if (doc.exists) {
        return doc.data()?['rating']?.toDouble();
      }
      return null;
    } catch (e) {
      print(' getUserRating error: $e');
      return null;
    }
  }

  /// Lấy tất cả rating của user
  Future<List<Map<String, dynamic>>> getUserRatings(String uid) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('ratings')
              .orderBy('ratedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print(' getUserRatings error: $e');
      return [];
    }
  }

  /// Stream ratings của user
  Stream<List<Map<String, dynamic>>> getUserRatingsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .orderBy('ratedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ACTIVITY LOG

  Future<void> logActivity(String uid, String action) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add({'action': action, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print(' logActivity error: $e');
    }
  }
}
