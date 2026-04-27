import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';

/// Notice item for app list.
class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.titleEn,
    this.bodyEn,
  });

  final String id;
  final String title;
  final String body;
  final String publishedAt;
  final String? titleEn;
  final String? bodyEn;

  /// Prefer English when locale is English and [titleEn]/[bodyEn] exist (API may already set [title]/[body]).
  String resolvedTitle(String languageCode) {
    if (languageCode.toLowerCase().startsWith('en')) {
      final t = titleEn?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return title;
  }

  String resolvedBody(String languageCode) {
    if (languageCode.toLowerCase().startsWith('en')) {
      final b = bodyEn?.trim();
      if (b != null && b.isNotEmpty) return b;
    }
    return body;
  }
}

String? _str(Map<String, dynamic> m, String camel, [String? snake]) {
  final a = m[camel];
  if (a is String) return a;
  if (snake != null) {
    final b = m[snake];
    if (b is String) return b;
  }
  return null;
}

/// Public notices API repository (no auth required).
class NoticeRepository {
  NoticeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<NoticeItem>> listPublished({String languageCode = 'ko'}) async {
    final preferEn = languageCode.toLowerCase().startsWith('en');
    final path =
        preferEn ? '${ApiEndpoints.notices}?locale=en' : ApiEndpoints.notices;
    final res = await _dio.get<dynamic>(path);
    final data = res.data;
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return NoticeItem(
        id: m['id']?.toString() ?? '',
        title: _str(m, 'title') ?? '',
        body: _str(m, 'body') ?? '',
        publishedAt: _str(m, 'publishedAt') ?? '',
        titleEn: _str(m, 'titleEn', 'title_en'),
        bodyEn: _str(m, 'bodyEn', 'body_en'),
      );
    }).toList();
  }

  Future<void> markNoticeRead(String noticeId) async {
    await _dio.post<void>(ApiEndpoints.noticeRead(noticeId));
  }
}
