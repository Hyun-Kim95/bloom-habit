import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_fable/core/errors/user_facing_error.dart';
import 'package:habit_fable/l10n/app_strings.dart';

void main() {
  setUp(() {
    AppStrings.localeCode = 'ko';
  });

  group('UserFacingError.resolve', () {
    test('connection timeout string maps to connection message', () {
      final msg = UserFacingError.resolve(
        'DioException [connection timeout]: The request took too long',
      );
      expect(msg, AppStrings.connectionErrorUser);
      expect(msg.contains('DioException'), isFalse);
    });

    test('PlatformException maps to generic unexpected', () {
      final msg = UserFacingError.resolve(
        PlatformException(code: 'sign_in_failed', message: 'ApiException: 10'),
      );
      expect(msg, AppStrings.unexpectedErrorTryAgain);
      expect(msg.contains('sign_in_failed'), isFalse);
      expect(msg.contains('ApiException'), isFalse);
    });

    test('generic Exception maps to unexpected', () {
      final msg = UserFacingError.resolve(Exception('Create habit failed'));
      expect(msg, AppStrings.unexpectedErrorTryAgain);
      expect(msg.contains('Create habit failed'), isFalse);
    });

    test('Dio 400 with Korean business message is shown', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/habits'),
        response: Response(
          requestOptions: RequestOptions(path: '/habits'),
          statusCode: 400,
          data: {'message': '비활성화된 계정입니다. 관리자에게 문의하세요.'},
        ),
        type: DioExceptionType.badResponse,
      );
      final msg = UserFacingError.resolve(dio);
      expect(msg, '비활성화된 계정입니다. 관리자에게 문의하세요.');
    });

    test('Dio 400 with English technical message maps to server generic', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {'message': 'Bad Request'},
        ),
        type: DioExceptionType.badResponse,
      );
      final msg = UserFacingError.resolve(dio);
      expect(msg, AppStrings.serverRequestFailed);
    });

    test('auth kind uses auth session message', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final msg = UserFacingError.resolve(dio, kind: UserFacingErrorKind.auth);
      expect(msg, AppStrings.authSessionExpired);
    });

    test('receive timeout Dio maps to slow response message', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.receiveTimeout,
      );
      final msg = UserFacingError.resolve(dio);
      expect(msg, AppStrings.serverSlowResponse);
    });
  });
}
