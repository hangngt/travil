import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/product_model.dart';

class ProductFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // GET LOCATIONS

  Future<List<String>> getLocations() async {
    try {
      final snapshot = await _firestore.collection("locations").get();

      final locations = snapshot.docs
          .map((doc) {
            final data = doc.data();

            return data["name"] ?? data["city"] ?? data["location"] ?? "";
          })
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      print("LOCATIONS: $locations");

      return locations;
    } catch (e) {
      print("GET LOCATION ERROR: $e");
      return [];
    }
  }
  // SEARCH PRODUCTS

  Future<List<ProductModel>> searchProducts(
    String query,
  ) async {
    try {
      final snapshot = await _firestore.collection("products").get();

      final lower = query.toLowerCase().trim();

      final results = snapshot.docs.where((
        doc,
      ) {
        final data = doc.data();

        final title = data["title"]?.toString().toLowerCase() ?? "";

        final location = data["location"]?.toString().toLowerCase() ?? "";

        return title.contains(lower) || location.contains(lower);
      }).map((doc) {
        final data = doc.data();

        return ProductModel.fromJson(
          data,
        );
      }).toList();

      return results;
    } catch (e) {
      print("SEARCH ERROR: $e");

      return [];
    }
  }
}
