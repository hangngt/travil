import 'package:flutter/material.dart';
import '../data/model/product_model.dart';
import '../data/services/firestore_service.dart';

class WillGoViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<ProductModel> willGoList = [];
  Set<int> selectedProducts = {};

  bool isLoading = false;

  Future<void> loadWillGoList(String uid) async {
    try {
      isLoading = true;
      notifyListeners();

      final data = await _firestore.getWillGoList(uid);

      willGoList = data.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("loadWillGoList error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToWillGo(
    String uid,
    ProductModel product,
  ) async {
    try {
      await _firestore.addToWillGo(
        uid,
        product.productId.toString(),
        product.toJson(),
      );

      if (!willGoList.any(
        (e) => e.productId == product.productId,
      )) {
        willGoList.insert(0, product);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("addToWillGo error: $e");
    }
  }

  Future<void> removeFromWillGo(
    String uid,
    int productId,
  ) async {
    try {
      await _firestore.removeFromWillGo(
        uid,
        productId.toString(),
      );

      willGoList.removeWhere(
        (e) => e.productId == productId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint("removeFromWillGo error: $e");
    }
  }
}
