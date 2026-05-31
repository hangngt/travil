import '../model/product_model.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService _apiService = ApiService();

  Future<List<ProductModel>> getRecommendations({
    String? city,
    double? lat,
    double? lng,
  }) async {
    final params = <String, dynamic>{};

    if (city != null) params['city'] = city;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;

    final data = await _apiService.getRecommendations(
      city: params['city'],
      lat: params['lat'],
      lng: params['lng'],
    );

    return data.map((e) => ProductModel.fromJson(e)).toList();
  }
}
