import 'package:flutter/material.dart';
import '../data/model/product_model.dart';
import '../data/services/firestore_service.dart';

class WillGoViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<ProductModel> willGoList = [];
  bool isLoading = false;

  // Load danh sách Will Go
  Future<void> loadWillGoList(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _firestore.getWillGoList(uid);
      willGoList = data.map((item) => ProductModel.fromJson(item)).toList();
    } catch (e) {
      print("Load WillGo error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // Thêm vào Will Go
  Future<void> addToWillGo(String uid, ProductModel product) async {
    try {
      await _firestore.addToWillGo(uid, product.productId.toString(), {
        'product_id': product.productId,
        'title': product.title,
        'image_url': product.imageUrl,
        'location': product.location,
        'price': product.price,
        'rating': product.rating,
      });

      if (!willGoList.any((p) => p.productId == product.productId)) {
        willGoList.insert(0, product);
        notifyListeners();
      }
    } catch (e) {
      print("Add to WillGo error: $e");
    }
  }

  // Xóa khỏi Will Go
  Future<void> removeFromWillGo(String uid, int productId) async {
    try {
      await _firestore.removeFromWillGo(uid, productId.toString());
      willGoList.removeWhere((p) => p.productId == productId);
      notifyListeners();
    } catch (e) {
      print("Remove from WillGo error: $e");
    }
  }
}
