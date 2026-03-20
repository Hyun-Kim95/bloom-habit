import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';

/// Legal document item for app display.
class LegalDocumentItem {
  const LegalDocumentItem({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

/// Legal documents API repository (public, no auth required).
class LegalRepository {
  LegalRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<LegalDocumentItem> getTerms() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.legalTerms);
    final data = res.data;
    if (data == null) return const LegalDocumentItem(title: '', content: '');
    return LegalDocumentItem(
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
    );
  }

  Future<LegalDocumentItem> getPrivacy() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.legalPrivacy);
    final data = res.data;
    if (data == null) return const LegalDocumentItem(title: '', content: '');
    return LegalDocumentItem(
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
    );
  }
}
