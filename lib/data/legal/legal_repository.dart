import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';

/// 약관/개인정보 한 건 (앱 표시용)
class LegalDocumentItem {
  const LegalDocumentItem({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

/// 약관·개인정보처리방침 API (공개, 인증 불필요)
class LegalRepository {
  LegalRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<LegalDocumentItem> getTerms() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.legalTerms);
    final data = res.data;
    if (data == null) return const LegalDocumentItem(title: '이용약관', content: '');
    return LegalDocumentItem(
      title: data['title'] as String? ?? '이용약관',
      content: data['content'] as String? ?? '',
    );
  }

  Future<LegalDocumentItem> getPrivacy() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.legalPrivacy);
    final data = res.data;
    if (data == null) return const LegalDocumentItem(title: '개인정보처리방침', content: '');
    return LegalDocumentItem(
      title: data['title'] as String? ?? '개인정보처리방침',
      content: data['content'] as String? ?? '',
    );
  }
}
