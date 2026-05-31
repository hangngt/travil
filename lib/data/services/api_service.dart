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
    try {
      final params = <String, dynamic>{};

      if (city != null) params['city'] = city;
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      if (userId != null) params['user_id'] = userId;

      print('PARAMS CLEAN: $params');

      final response = await dio.get(
        '/recommend',
        queryParameters: params,
      );

      print('SUCCESS: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('STATUS: ${e.response?.statusCode}');
      print('URI: ${e.requestOptions.uri}');
      print('DATA: ${e.response?.data}');
      throw Exception(e.response?.data ?? e.message);
    }
  }
}
