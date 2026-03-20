import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../local/entity/local_habit_record.dart';
import '../local/entity/local_habit.dart';
import '../../core/network/api_endpoints.dart';

/// 기록 요약 (히스토리 목록용)
class RecordSummary {
  const RecordSummary({
    required this.recordDate,
    required this.completed,
    this.recordId,
  });
  final String recordDate;
  final bool completed;
  final String? recordId;
}

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

  /// 회원 탈퇴 등 시 로컬 습관·기록 전체 삭제
  Future<void> clearAllLocalData() async {
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      await isar.localHabits.clear();
      await isar.localHabitRecords.clear();
    });
  }

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

  /// 지난 N일 동안 습관별 완료한 날 수 (통계 일/주/월용). habitId -> 완료한 날 수.
  Future<Map<String, int>> getCompletedCountByHabitForDays(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getCompletedCountByHabitForDateRange(start, end);
  }

  /// 오늘 포함 최근 7일(rolling) 성공률. 분모 = 활성 습관마다 해당 기간·시작일 기준 '해야 할 날' 수,
  /// 분자 = 그중 완료한 (습관·날) 쌍 수(같은 날 중복 완료는 1회로 침).
  Future<({int completed, int possible, int percent})> getRolling7DaySuccessRate() async {
    final habits = await getActiveHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 6));

    final startByHabit = <String, DateTime>{};
    int possible = 0;
    for (final h in habits) {
      final id = h.serverId;
      if (id == null) continue;
      final sd = h.startDate;
      final habitStart = sd != null
          ? DateTime(sd.year, sd.month, sd.day)
          : windowStart;
      startByHabit[id] = habitStart;
      var d = windowStart;
      while (!d.isAfter(today)) {
        if (!d.isBefore(habitStart)) possible++;
        d = d.add(const Duration(days: 1));
      }
    }

    if (possible == 0) {
      return (completed: 0, possible: 0, percent: 0);
    }

    final isar = await _isarFuture;
    final endExclusive = today.add(const Duration(days: 1));
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(windowStart, endExclusive, includeLower: true, includeUpper: false)
        .completedEqualTo(true)
        .findAll();

    final completedKeys = <String>{};
    for (final r in records) {
      final hid = r.habitId;
      if (hid == null || r.recordDate == null) continue;
      final habitStart = startByHabit[hid];
      if (habitStart == null) continue;
      final rd = r.recordDate!.toLocal();
      final day = DateTime(rd.year, rd.month, rd.day);
      if (day.isBefore(windowStart) || day.isAfter(today)) continue;
      if (day.isBefore(habitStart)) continue;
      completedKeys.add('$hid|${_dateString(day)}');
    }

    final completed = completedKeys.length;
    final percent = ((completed / possible) * 100).round().clamp(0, 100);
    return (completed: completed, possible: possible, percent: percent);
  }

  /// 지정 기간 [start, end] (start·end 포함, 로컬 날짜 기준) 습관별 완료 횟수. habitId -> 완료 횟수.
  Future<Map<String, int>> getCompletedCountByHabitForDateRange(DateTime start, DateTime end) async {
    final isar = await _isarFuture;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final endExclusive = endDay.add(const Duration(days: 1));
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(startDay, endExclusive, includeLower: true, includeUpper: false)
        .completedEqualTo(true)
        .findAll();
    final map = <String, int>{};
    for (final r in records) {
      if (r.habitId != null) {
        map[r.habitId!] = (map[r.habitId!] ?? 0) + 1;
      }
    }
    return map;
  }

  /// 지난 28일 중 완료 기록이 있는 날짜 집합 (히트맵용). 로컬 날짜 기준.
  Future<Set<String>> getLast28DaysCompletedDates() async {
    final counts = await getLast28DaysCompletionCounts();
    return counts.keys.toSet();
  }

  /// 지난 28일 날짜별 완료 기록 개수 (히트맵 색 농도용). 로컬 날짜 기준.
  Future<Map<String, int>> getLast28DaysCompletionCounts() async {
    final isar = await _isarFuture;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 27));
    final end = DateTime(now.year, now.month, now.day);
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(start, end, includeLower: true, includeUpper: true)
        .completedEqualTo(true)
        .findAll();
    final counts = <String, int>{};
    for (final r in records) {
      if (r.recordDate != null) {
        final d = r.recordDate!.toLocal();
        final key = _dateString(DateTime(d.year, d.month, d.day));
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
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

  /// 습관 수정 (API + 로컬 반영)
  Future<LocalHabit> updateHabit(
    String serverId, {
    String? name,
    String? category,
    String? goalType,
    double? goalValue,
    String? colorHex,
    String? iconName,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (goalType != null) body['goalType'] = goalType;
    if (goalValue != null) body['goalValue'] = goalValue;
    if (colorHex != null) body['colorHex'] = colorHex;
    if (iconName != null) body['iconName'] = iconName;
    final res = await _dio.patch<Map<String, dynamic>>(ApiEndpoints.habits(serverId), data: body);
    if (res.data == null) throw Exception('Update habit failed');
    final isar = await _isarFuture;
    final local = _habitDtoToLocal(res.data!);
    final existing = await isar.localHabits.getByServerId(serverId);
    if (existing != null) {
      local.id = existing.id;
      local.reminderEnabled = existing.reminderEnabled;
      local.reminderHour = existing.reminderHour;
      local.reminderMinute = existing.reminderMinute;
    }
    await isar.writeTxn(() async => isar.localHabits.put(local));
    return local;
  }

  /// 습관 보관 (API + 로컬에 archivedAt 반영)
  Future<void> archiveHabit(String serverId) async {
    final res = await _dio.patch<Map<String, dynamic>>(ApiEndpoints.habitArchive(serverId));
    if (res.data == null) return;
    final isar = await _isarFuture;
    final local = _habitDtoToLocal(res.data!);
    final existing = await isar.localHabits.getByServerId(serverId);
    if (existing != null) {
      local.id = existing.id;
      local.reminderEnabled = existing.reminderEnabled;
      local.reminderHour = existing.reminderHour;
      local.reminderMinute = existing.reminderMinute;
    }
    await isar.writeTxn(() async => isar.localHabits.put(local));
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

  /// 습관 기록 목록 (서버, 기간 지정)
  Future<List<RecordSummary>> getRecordHistory(
    String habitServerId, {
    DateTime? from,
    DateTime? to,
  }) async {
    String? fromStr = from != null ? _dateString(from) : null;
    String? toStr = to != null ? _dateString(to) : null;
    var url = ApiEndpoints.habitRecords(habitServerId);
    if (fromStr != null || toStr != null) {
      final q = <String>[];
      if (fromStr != null) q.add('from=$fromStr');
      if (toStr != null) q.add('to=$toStr');
      url = '$url?${q.join('&')}';
    }
    final res = await _dio.get<List<dynamic>>(url);
    if (res.data == null) return [];
    return (res.data!)
        .map((e) {
          final m = e as Map<String, dynamic>?;
          if (m == null) return null;
          return RecordSummary(
            recordDate: m['recordDate'] as String? ?? '',
            completed: m['completed'] as bool? ?? false,
            recordId: m['id'] as String?,
          );
        })
        .whereType<RecordSummary>()
        .toList();
  }

  /// 기록 수정 (API + 로컬)
  Future<void> updateRecord(
    String habitServerId,
    String recordServerId, {
    bool? completed,
    double? value,
  }) async {
    final body = <String, dynamic>{};
    if (completed != null) body['completed'] = completed;
    if (value != null) body['value'] = value;
    if (body.isEmpty) return;
    await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.habitRecords(habitServerId, recordServerId),
      data: body,
    );
    final isar = await _isarFuture;
    final existing = await isar.localHabitRecords.getByServerId(recordServerId);
    if (existing != null) {
      if (completed != null) existing.completed = completed;
      if (value != null) existing.value = value;
      await isar.writeTxn(() async => isar.localHabitRecords.put(existing));
    }
  }

  /// 기록 삭제 (API + 로컬)
  Future<void> deleteRecord(String habitServerId, String recordServerId) async {
    await _dio.delete(ApiEndpoints.habitRecords(habitServerId, recordServerId));
    final isar = await _isarFuture;
    final existing = await isar.localHabitRecords.getByServerId(recordServerId);
    if (existing != null) {
      await isar.writeTxn(() async => isar.localHabitRecords.delete(existing.id));
    }
  }

  /// 습관의 연속 달성일 (로컬, 오늘 포함 역순). 날짜는 로컬 날짜 키로 비교해 타임존 이슈 방지.
  Future<int> getStreakDays(String habitServerId) async {
    final isar = await _isarFuture;
    final habit = await isar.localHabits.getByServerId(habitServerId);
    if (habit == null || habit.startDate == null) return 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final startDay = DateTime(habit.startDate!.year, habit.startDate!.month, habit.startDate!.day);
    // 지난 365일 구간의 완료 기록을 가져와 로컬 날짜 키(YYYY-MM-DD) 집합으로 만든 뒤, 오늘부터 역순으로 연속 여부 확인
    final end = today.add(const Duration(days: 1));
    final start = today.subtract(const Duration(days: 365));
    final records = await isar.localHabitRecords
        .filter()
        .habitIdEqualTo(habitServerId)
        .recordDateBetween(start, end, includeLower: true, includeUpper: false)
        .completedEqualTo(true)
        .findAll();
    final completedDateKeys = <String>{};
    for (final r in records) {
      if (r.recordDate != null) {
        final local = r.recordDate!.toLocal();
        completedDateKeys.add(_dateString(DateTime(local.year, local.month, local.day)));
      }
    }
    int streak = 0;
    for (int offset = 0; offset < 365; offset++) {
      final d = today.subtract(Duration(days: offset));
      if (d.isBefore(startDay)) break;
      final key = _dateString(d);
      if (!completedDateKeys.contains(key)) break;
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
