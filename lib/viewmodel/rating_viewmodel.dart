import 'package:flutter/material.dart';
import 'package:travil/data/services/firestore_service.dart';

class RatingViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = false;

  Future<void> addRating({
    required String uid,
    required String productId,
    required String title,
    required double rating,
    String? review,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      await _firestoreService.addRating(
        uid: uid,
        productId: productId,
        rating: rating,
        title: title,
        review: review,
      );
    } catch (e) {
      debugPrint("Rating error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getRatingHistory(String uid) {
    return _firestoreService.getUserRatingsStream(uid);
  }
}
