import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/model/product_model.dart';

class PlannedViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> plannedProducts = [];

  bool isLoading = false;

  Future<void> loadPlannedByMonth({
    required String uid,
    required int month,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('trip_status')
          .where('status', isEqualTo: 'planned')
          .get();

      plannedProducts = snapshot.docs
          .map(
            (e) => ProductModel.fromJson(
              e.data(),
            ),
          )
          .where(
            (product) =>
                product.plannedDate != null &&
                product.plannedDate!.month == month,
          )
          .toList();
    } catch (e) {
      debugPrint(
        "loadPlannedByMonth error: $e",
      );
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
