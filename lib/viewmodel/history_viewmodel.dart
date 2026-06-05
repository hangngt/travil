import 'package:flutter/material.dart';
import 'package:travil/data/services/firestore_service.dart';

import '../data/model/product_model.dart';

class HistoryViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductModel> historyList = [];

  bool isLoading = false;

  Future<void> loadHistory(String uid) async {
    try {
      isLoading = true;
      notifyListeners();

      final data = await _firestoreService.getHistory(uid);

      historyList = data.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
