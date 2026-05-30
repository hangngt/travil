import '../model/product_model.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService _apiService = ApiService();

  Future<List<ProductModel>> getRecommendations({
    String? city,
    double? lat,
    double? lng,
  }) async {
    final data = await _apiService.getRecommendations(
      city: city,
      lat: lat,
      lng: lng,
    );
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }
}
