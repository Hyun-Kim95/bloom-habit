import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';

/// Notice item for app list.
class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final String publishedAt;
}

/// Public notices API repository (no auth required).
class NoticeRepository {
  NoticeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<NoticeItem>> listPublished() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.notices);
    final data = res.data;
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return NoticeItem(
        id: m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        publishedAt: m['publishedAt'] as String? ?? '',
      );
    }).toList();
  }
}
