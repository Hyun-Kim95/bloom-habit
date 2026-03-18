import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../local/entity/local_habit_record.dart';
import '../local/entity/local_habit.dart';
import '../../core/network/api_endpoints.dart';

/// AI 피드백 한 건 (통계 목록용)
class AiFeedbackItem {
  const AiFeedbackItem({
    required this.habitId,
    required this.habitName,
    required this.recordDate,
    required this.responseText,
    required this.createdAt,
  });
  final String habitId;
  final String habitName;
  final String recordDate;
  final String responseText;
  final String createdAt;
}

/// 습관·기록 API + 로컬 Isar (로그인 후 sync 풀, CRUD는 API 호출 후 로컬 반영)
class HabitRepository {
  HabitRepository({
    required Dio dio,
    required Future<Isar> isarFuture,
  })  : _dio = dio,
        _isarFuture = isarFuture;

  final Dio _dio;
  final Future<Isar> _isarFuture;

  /// 서버에서 풀 후 로컬에 저장
  Future<void> syncFromServer() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.sync);
    if (res.data == null) return;
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      final habits = res.data!['habits'] as List<dynamic>?;
      if (habits != null) {
        for (final h in habits) {
          final map = h as Map<String, dynamic>;
          final local = LocalHabit()
            ..serverId = map['id'] as String?
            ..userId = map['userId'] as String?
            ..name = map['name'] as String?
            ..category = map['category'] as String?
            ..goalType = map['goalType'] as String?
            ..goalValue = (map['goalValue'] as num?)?.toDouble()
            ..startDate = _parseDate(map['startDate'])
            ..colorHex = map['colorHex'] as String?
            ..iconName = map['iconName'] as String?
            ..archivedAt = _parseDateTime(map['archivedAt'])
            ..createdAt = _parseDateTime(map['createdAt'])
            ..updatedAt = _parseDateTime(map['updatedAt']);
          if (local.serverId != null) {
            final existing = await isar.localHabits.getByServerId(local.serverId);
            if (existing != null) {
              local.id = existing.id;
              local.reminderEnabled = existing.reminderEnabled;
              local.reminderHour = existing.reminderHour;
              local.reminderMinute = existing.reminderMinute;
            }
            await isar.localHabits.put(local);
          }
        }
      }
      final records = res.data!['records'] as List<dynamic>?;
      if (records != null) {
        for (final r in records) {
          final map = r as Map<String, dynamic>;
          final local = LocalHabitRecord()
            ..serverId = map['id'] as String?
            ..habitId = map['habitId'] as String?
            ..recordDate = _parseDate(map['recordDate'])
            ..value = (map['value'] as num?)?.toDouble()
            ..completed = map['completed'] as bool?
            ..createdAt = _parseDateTime(map['createdAt'])
            ..updatedAt = _parseDateTime(map['updatedAt']);
          if (local.serverId != null) {
            final existing = await isar.localHabitRecords.getByServerId(local.serverId);
            if (existing != null) local.id = existing.id;
            await isar.localHabitRecords.put(local);
          }
        }
      }
    });
  }

  /// 습관 카테고리 목록 (관리자에서 설정, 앱에서 선택용)
  Future<List<String>> getHabitCategories() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.habitCategories);
    if (res.data is! List) return [];
    return (res.data as List)
        .map((e) => e?.toString().trim())
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 활성 습관 목록 (로컬)
  Future<List<LocalHabit>> getActiveHabits() async {
    final isar = await _isarFuture;
    return isar.localHabits
        .filter()
        .archivedAtIsNull()
        .findAll();
  }

  /// serverId로 습관 한 건 조회 (로컬)
  Future<LocalHabit?> getHabitByServerId(String serverId) async {
    final isar = await _isarFuture;
    return isar.localHabits.getByServerId(serverId);
  }

  /// 습관별 리마인더 알림 설정만 로컬 갱신 (서버 미동기화)
  Future<void> updateLocalReminder({
    required String serverId,
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final isar = await _isarFuture;
    final existing = await isar.localHabits.getByServerId(serverId);
    if (existing == null) return;
    existing.reminderEnabled = enabled;
    existing.reminderHour = hour;
    existing.reminderMinute = minute;
    await isar.writeTxn(() async => isar.localHabits.put(existing));
  }

  /// 오늘 날짜 문자열 (YYYY-MM-DD)
  static String todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// 습관별 오늘 기록 여부 (로컬)
  Future<Map<String, bool>> getTodayCompletedByHabit() async {
    final isar = await _isarFuture;
    final today = todayString();
    final records = await isar.localHabitRecords
        .filter()
        .recordDateEqualTo(DateTime.parse(today))
        .completedEqualTo(true)
        .findAll();
    final map = <String, bool>{};
    for (final r in records) {
      if (r.habitId != null) map[r.habitId!] = true;
    }
    return map;
  }

  /// 지난 28일 중 완료 기록이 있는 날짜 집합 (히트맵용). 로컬 날짜 기준.
  Future<Set<String>> getLast28DaysCompletedDates() async {
    final isar = await _isarFuture;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 27));
    final end = DateTime(now.year, now.month, now.day);
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(start, end, includeLower: true, includeUpper: true)
        .completedEqualTo(true)
        .findAll();
    final set = <String>{};
    for (final r in records) {
      if (r.recordDate != null) {
        final d = r.recordDate!.toLocal();
        set.add(_dateString(DateTime(d.year, d.month, d.day)));
      }
    }
    return set;
  }

  /// 습관 생성 (API + 로컬)
  Future<LocalHabit> createHabit({
    required String name,
    String? category,
    String goalType = 'completion',
    double? goalValue,
    required DateTime startDate,
    String? colorHex,
    String? iconName,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'goalType': goalType,
      'startDate': _dateString(startDate),
    };
    if (category != null) body['category'] = category;
    if (goalValue != null) body['goalValue'] = goalValue;
    if (colorHex != null) body['colorHex'] = colorHex;
    if (iconName != null) body['iconName'] = iconName;

    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.habits(),
      data: body,
    );
    if (res.data == null) throw Exception('Create habit failed');
    final isar = await _isarFuture;
    final local = _habitDtoToLocal(res.data!);
    await isar.writeTxn(() async => isar.localHabits.put(local));
    return local;
  }

  /// 습관 삭제 (API + 로컬)
  Future<void> deleteHabit(String serverId) async {
    await _dio.delete(ApiEndpoints.habits(serverId));
    final isar = await _isarFuture;
    final existing = await isar.localHabits.getByServerId(serverId);
    if (existing != null) {
      await isar.writeTxn(() async => isar.localHabits.delete(existing.id));
    }
  }

  /// 오늘 기록 추가 (API + 로컬)
  Future<LocalHabitRecord> recordToday(String habitServerId, {bool completed = true}) async {
    final today = todayString();
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.habitRecords(habitServerId),
      data: {'recordDate': today, 'completed': completed},
    );
    if (res.data == null) throw Exception('Record failed');
    final isar = await _isarFuture;
    final local = _recordDtoToLocal(res.data!, habitServerId);
    await isar.writeTxn(() async {
      final existing = await isar.localHabitRecords.getByServerId(local.serverId);
      if (existing != null) local.id = existing.id;
      isar.localHabitRecords.put(local);
    });
    return local;
  }

  /// 통계용: 최근 AI 피드백 목록 (습관명·날짜·코멘트)
  Future<List<AiFeedbackItem>> getAiFeedbackList({int limit = 30}) async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.aiFeedbackList(limit));
      if (res.data == null) return [];
      return (res.data!)
          .map((e) {
            final m = e as Map<String, dynamic>?;
            if (m == null) return null;
            return AiFeedbackItem(
              habitId: m['habitId'] as String? ?? '',
              habitName: m['habitName'] as String? ?? '',
              recordDate: m['recordDate'] as String? ?? '',
              responseText: m['responseText'] as String? ?? '',
              createdAt: _parseDateTime(m['createdAt'])?.toIso8601String() ?? '',
            );
          })
          .whereType<AiFeedbackItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// AI 코멘트 요청 (기록 완료 직후). 실패/429 시 fallback 반환.
  Future<String> requestAiFeedback(String habitServerId, String recordServerId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiFeedback(habitServerId, recordServerId),
      );
      final text = res.data?['response_text'] as String?;
      return text ?? '오늘도 수고했어요!';
    } catch (_) {
      return '오늘도 수고했어요!';
    }
  }

  /// 습관의 연속 달성일 (로컬, 오늘 포함 역순)
  Future<int> getStreakDays(String habitServerId) async {
    final isar = await _isarFuture;
    final habit = await isar.localHabits.getByServerId(habitServerId);
    if (habit == null || habit.startDate == null) return 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final startDay = DateTime(habit.startDate!.year, habit.startDate!.month, habit.startDate!.day);
    int streak = 0;
    for (int offset = 0; offset < 365; offset++) {
      final d = today.subtract(Duration(days: offset));
      if (d.isBefore(startDay)) break;
      final records = await isar.localHabitRecords
          .filter()
          .habitIdEqualTo(habitServerId)
          .recordDateEqualTo(d)
          .completedEqualTo(true)
          .findAll();
      if (records.isEmpty) break;
      streak++;
    }
    return streak;
  }

  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  LocalHabit _habitDtoToLocal(Map<String, dynamic> map) => LocalHabit()
    ..serverId = map['id'] as String?
    ..userId = map['userId'] as String?
    ..name = map['name'] as String?
    ..category = map['category'] as String?
    ..goalType = map['goalType'] as String?
    ..goalValue = (map['goalValue'] as num?)?.toDouble()
    ..startDate = _parseDate(map['startDate'])
    ..colorHex = map['colorHex'] as String?
    ..iconName = map['iconName'] as String?
    ..archivedAt = _parseDateTime(map['archivedAt'])
    ..createdAt = _parseDateTime(map['createdAt'])
    ..updatedAt = _parseDateTime(map['updatedAt']);

  LocalHabitRecord _recordDtoToLocal(Map<String, dynamic> map, String habitId) =>
      LocalHabitRecord()
        ..serverId = map['id'] as String?
        ..habitId = habitId
        ..recordDate = _parseDate(map['recordDate'])
        ..value = (map['value'] as num?)?.toDouble()
        ..completed = map['completed'] as bool?
        ..createdAt = _parseDateTime(map['createdAt'])
        ..updatedAt = _parseDateTime(map['updatedAt']);
}
