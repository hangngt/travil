import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiService {
  late final Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://travil-m2kl.onrender.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<List<dynamic>> getRecommendations({
    String? city,
    double? lat,
    double? lng,
    String? userId,
  }) async {
    try {
      final params = <String, dynamic>{};

      if (city != null && city.isNotEmpty) {
        params['city'] = city;
      }

      if (lat != null) {
        params['lat'] = lat;
      }

      if (lng != null) {
        params['lng'] = lng;
      }

      if (userId != null) {
        params['user_id'] = userId;
      }

      debugPrint("CALL API");
      debugPrint("PARAMS: $params");

      final response = await dio.get(
        '/recommend',
        queryParameters: params,
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("DATA: ${response.data}");

      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }

      return [];
    } on DioException catch (e) {
      debugPrint("DIO ERROR");
      debugPrint("MESSAGE: ${e.message}");
      debugPrint("STATUS: ${e.response?.statusCode}");
      debugPrint("DATA: ${e.response?.data}");
      return [];
    } catch (e) {
      debugPrint("ERROR: $e");
      return [];
    }
  }
}
