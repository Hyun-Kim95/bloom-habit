import 'package:dio/dio.dart';

/// Shared API error handling and retry interception.
class ApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: implement refresh/retry for 401 and policy for 429.
    super.onError(err, handler);
  }
}
