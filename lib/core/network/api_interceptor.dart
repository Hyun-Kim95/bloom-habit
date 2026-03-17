import 'package:dio/dio.dart';

/// 401 시 토큰 갱신·재시도, 공통 에러 로깅
class ApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: 401 시 refresh 후 재요청, 429 등 처리
    super.onError(err, handler);
  }
}
