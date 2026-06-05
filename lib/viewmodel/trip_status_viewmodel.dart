import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/model/product_model.dart';
import '../data/services/firestore_service.dart';

class TripStatusViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductModel> visitedProducts = [];

  bool isLoading = false;

  Future<void> updateStatus({
    required String uid,
    required ProductModel product,
    required String status,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      await _firestoreService.updateTripStatus(
        uid: uid,
        productId: product.productId.toString(),
        status: status,
        product: product, //sửa
      );
    } catch (e) {
      debugPrint("updateStatus error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVisitedPlaces(
    String uid,
  ) async {
    try {
      isLoading = true;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trip_status')
          .where('status', isEqualTo: 'visited')
          .get();

      visitedProducts = snapshot.docs
          .map(
            (e) => ProductModel.fromJson(e.data()),
          )
          .toList();
    } catch (e) {
      debugPrint("loadVisitedPlaces error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
