import 'package:dio/dio.dart';

import 'api_interceptor.dart';

/// Backend API client with shared auth/error handling.
class ApiClient {
  ApiClient({required String baseUrl, String? accessToken}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    ));
    _dio.interceptors.add(ApiInterceptor());
  }

  late final Dio _dio;
  Dio get dio => _dio;

  void setAccessToken(String? token) {
    _dio.options.headers['Authorization'] =
        token != null ? 'Bearer $token' : null;
  }
}
