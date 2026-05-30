import 'package:dio/dio.dart';

import '../errors/error_logger.dart';

/// Shared API error handling and retry interception.
class ApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ErrorLogger.logError(
      'ApiInterceptor ${err.requestOptions.method} ${err.requestOptions.path}',
      err,
      err.stackTrace,
    );
    // TODO: implement refresh/retry for 401 and policy for 429.
    super.onError(err, handler);
  }
}
