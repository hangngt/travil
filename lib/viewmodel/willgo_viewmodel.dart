import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/model/product_model.dart';

class WillGoViewModel extends ChangeNotifier {
  List<ProductModel> willGoList = [];

  Future<void> loadWillGoList() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('will_go_list') ?? [];

    // Ở đây bạn có thể load từ API hoặc local cache
    // Hiện tại giả lập từ danh sách đã lưu
    willGoList = []; // Thay bằng logic load thực tế
    notifyListeners();
  }

  Future<void> addToWillGo(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('will_go_list') ?? [];

    if (!saved.contains(product.productId.toString())) {
      saved.add(product.productId.toString());
      await prefs.setStringList('will_go_list', saved);
      willGoList.add(product);
      notifyListeners();
    }
  }

  Future<void> removeFromWillGo(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('will_go_list') ?? [];
    saved.remove(productId.toString());
    await prefs.setStringList('will_go_list', saved);

    willGoList.removeWhere((p) => p.productId == productId);
    notifyListeners();
  }
}
