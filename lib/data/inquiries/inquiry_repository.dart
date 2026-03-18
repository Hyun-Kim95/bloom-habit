import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';

/// 문의 한 건 (앱에서 사용)
class InquiryItem {
  const InquiryItem({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    this.adminReply,
    this.repliedAt,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String body;
  final String status;
  final String? adminReply;
  final String? repliedAt;
  final String createdAt;
}

/// 문의 API (게시판 형식)
class InquiryRepository {
  InquiryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// 내 문의 목록
  Future<List<InquiryItem>> getMyInquiries() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.inquiries);
    if (res.data == null) return [];
    return (res.data!)
        .map((e) {
          final m = e as Map<String, dynamic>?;
          if (m == null) return null;
          return InquiryItem(
            id: m['id'] as String? ?? '',
            subject: m['subject'] as String? ?? '',
            body: m['body'] as String? ?? '',
            status: m['status'] as String? ?? 'pending',
            adminReply: m['adminReply'] as String?,
            repliedAt: m['repliedAt'] as String?,
            createdAt: m['createdAt'] as String? ?? '',
          );
        })
        .whereType<InquiryItem>()
        .toList();
  }

  /// 문의 등록
  Future<InquiryItem> createInquiry({required String subject, required String body}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.inquiries,
      data: {'subject': subject, 'body': body},
    );
    if (res.data == null) throw Exception('문의 등록에 실패했습니다.');
    final m = res.data!;
    return InquiryItem(
      id: m['id'] as String? ?? '',
      subject: m['subject'] as String? ?? '',
      body: m['body'] as String? ?? '',
      status: m['status'] as String? ?? 'pending',
      adminReply: m['adminReply'] as String?,
      repliedAt: m['repliedAt'] as String?,
      createdAt: m['createdAt'] as String? ?? '',
    );
  }
}
