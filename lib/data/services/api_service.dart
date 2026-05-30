import 'package:dio/dio.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://travil-m2kl.onrender.com',
      connectTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<dynamic>> getRecommendations({
    String? city,
    double? lat,
    double? lng,
    String? userId,
  }) async {
    final response = await dio.get(
      '/recommend',
      queryParameters: {
        'city': city,
        'lat': lat,
        'lng': lng,
        'user_id': userId,
      },
    );
    return response.data;
  }
}
