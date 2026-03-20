import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../local/entity/local_habit_record.dart';
import '../local/entity/local_habit.dart';
import '../../core/network/api_endpoints.dart';

/// Record summary for history list.
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

class HabitTemplateItem {
  const HabitTemplateItem({
    required this.id,
    required this.name,
    this.category,
    required this.goalType,
    this.goalValue,
    this.colorHex,
    this.iconName,
  });

  final String id;
  final String name;
  final String? category;
  final String goalType;
  final double? goalValue;
  final String? colorHex;
  final String? iconName;
}

/// Habit/record repository with API + local Isar persistence.
class HabitRepository {
  HabitRepository({required Dio dio, required Future<Isar> isarFuture})
    : _dio = dio,
      _isarFuture = isarFuture;

  final Dio _dio;
  final Future<Isar> _isarFuture;

  /// Clear all local habit/record data.
  Future<void> clearAllLocalData() async {
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      await isar.localHabits.clear();
      await isar.localHabitRecords.clear();
    });
  }

  /// Pull from server and store into local DB.
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
            final existing = await isar.localHabits.getByServerId(
              local.serverId,
            );
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
            final existing = await isar.localHabitRecords.getByServerId(
              local.serverId,
            );
            if (existing != null) local.id = existing.id;
            await isar.localHabitRecords.put(local);
          }
        }
      }
    });
  }

  /// Habit category list (managed by admin).
  Future<List<String>> getHabitCategories() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.habitCategories);
    if (res.data is! List) return [];
    return (res.data as List)
        .map((e) => e?.toString().trim())
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<List<HabitTemplateItem>> getHabitTemplates() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.habitTemplates);
    if (res.data is! List) return [];
    return (res.data as List)
        .map((e) {
          final m = e as Map<String, dynamic>?;
          if (m == null) return null;
          return HabitTemplateItem(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            category: m['category'] as String?,
            goalType: m['goalType'] as String? ?? 'completion',
            goalValue: (m['goalValue'] as num?)?.toDouble(),
            colorHex: m['colorHex'] as String?,
            iconName: m['iconName'] as String?,
          );
        })
        .whereType<HabitTemplateItem>()
        .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
        .toList();
  }

  /// Active habit list from local DB.
  Future<List<LocalHabit>> getActiveHabits() async {
    final isar = await _isarFuture;
    return isar.localHabits.filter().archivedAtIsNull().findAll();
  }

  /// Hidden (archived) habits from local DB.
  Future<List<LocalHabit>> getHiddenHabits() async {
    final isar = await _isarFuture;
    return isar.localHabits.filter().archivedAtIsNotNull().findAll();
  }

  /// Fetch one habit by serverId from local DB.
  Future<LocalHabit?> getHabitByServerId(String serverId) async {
    final isar = await _isarFuture;
    return isar.localHabits.getByServerId(serverId);
  }

  /// Update reminder fields locally only (no server sync).
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

  /// Today's date string (YYYY-MM-DD).
  static String todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Today's completion status by habit (local).
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

  /// Completed day count by habit for last N days.
  Future<Map<String, int>> getCompletedCountByHabitForDays(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getCompletedCountByHabitForDateRange(start, end);
  }

  /// Success rate for a local date range (same logic as rolling 7-day rate).
  /// Denominator: required habit-days after each habit start date.
  /// Numerator: completed habit-day pairs (deduped per day).
  Future<({int completed, int possible, int percent})>
  getSuccessRateForDateRange(
    DateTime rangeStart,
    DateTime rangeEndInclusive,
  ) async {
    final habits = await getActiveHabits();
    final windowStart = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final endDay = DateTime(
      rangeEndInclusive.year,
      rangeEndInclusive.month,
      rangeEndInclusive.day,
    );

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
      while (!d.isAfter(endDay)) {
        if (!d.isBefore(habitStart)) possible++;
        d = d.add(const Duration(days: 1));
      }
    }

    if (possible == 0) {
      return (completed: 0, possible: 0, percent: 0);
    }

    final isar = await _isarFuture;
    final endExclusive = endDay.add(const Duration(days: 1));
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(
          windowStart,
          endExclusive,
          includeLower: true,
          includeUpper: false,
        )
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
      if (day.isBefore(windowStart) || day.isAfter(endDay)) continue;
      if (day.isBefore(habitStart)) continue;
      completedKeys.add('$hid|${_dateString(day)}');
    }

    final completed = completedKeys.length;
    final percent = ((completed / possible) * 100).round().clamp(0, 100);
    return (completed: completed, possible: possible, percent: percent);
  }

  Future<({int completed, int possible, int percent})>
  getRolling7DaySuccessRate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 6));
    return getSuccessRateForDateRange(windowStart, today);
  }

  /// Completion count by habit for inclusive [start, end] local date range.
  Future<Map<String, int>> getCompletedCountByHabitForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final isar = await _isarFuture;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final endExclusive = endDay.add(const Duration(days: 1));
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(
          startDay,
          endExclusive,
          includeLower: true,
          includeUpper: false,
        )
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

  /// Date set with completions in the last 28 days (heatmap).
  Future<Set<String>> getLast28DaysCompletedDates() async {
    final counts = await getLast28DaysCompletionCounts();
    return counts.keys.toSet();
  }

  /// Daily completion counts for inclusive [start, end] range (heatmap).
  Future<Map<String, int>> getCompletionCountsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final isar = await _isarFuture;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final records = await isar.localHabitRecords
        .filter()
        .recordDateBetween(
          startDay,
          endDay,
          includeLower: true,
          includeUpper: true,
        )
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

  /// Last-28-days daily completion counts (heatmap intensity).
  Future<Map<String, int>> getLast28DaysCompletionCounts() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 27));
    return getCompletionCountsForDateRange(start, end);
  }

  /// Create habit (API + local upsert).
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

  /// Update habit (API + local update).
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
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.habits(serverId),
      data: body,
    );
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

  /// Archive habit (API + local archivedAt update).
  Future<void> archiveHabit(String serverId) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.habitArchive(serverId),
    );
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

  /// Delete habit (API + local delete).
  Future<void> deleteHabit(String serverId) async {
    await _dio.delete(ApiEndpoints.habits(serverId));
    final isar = await _isarFuture;
    final existing = await isar.localHabits.getByServerId(serverId);
    if (existing != null) {
      await isar.writeTxn(() async => isar.localHabits.delete(existing.id));
    }
  }

  /// Add today's record (API + local upsert).
  Future<LocalHabitRecord> recordToday(
    String habitServerId, {
    bool completed = true,
  }) async {
    final today = todayString();
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.habitRecords(habitServerId),
      data: {'recordDate': today, 'completed': completed},
    );
    if (res.data == null) throw Exception('Record failed');
    final isar = await _isarFuture;
    final local = _recordDtoToLocal(res.data!, habitServerId);
    await isar.writeTxn(() async {
      final existing = await isar.localHabitRecords.getByServerId(
        local.serverId,
      );
      if (existing != null) local.id = existing.id;
      isar.localHabitRecords.put(local);
    });
    return local;
  }

  /// Habit record history from server (optional period filter).
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

  /// Update record (API + local update).
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

  /// Delete record (API + local delete).
  Future<void> deleteRecord(String habitServerId, String recordServerId) async {
    await _dio.delete(ApiEndpoints.habitRecords(habitServerId, recordServerId));
    final isar = await _isarFuture;
    final existing = await isar.localHabitRecords.getByServerId(recordServerId);
    if (existing != null) {
      await isar.writeTxn(
        () async => isar.localHabitRecords.delete(existing.id),
      );
    }
  }

  /// Habit streak in local dates, counting backward from today.
  Future<int> getStreakDays(String habitServerId) async {
    final isar = await _isarFuture;
    final habit = await isar.localHabits.getByServerId(habitServerId);
    if (habit == null || habit.startDate == null) return 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final startDay = DateTime(
      habit.startDate!.year,
      habit.startDate!.month,
      habit.startDate!.day,
    );
    // Build a local-date key set from last 365 days and count contiguous days from today.
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
        completedDateKeys.add(
          _dateString(DateTime(local.year, local.month, local.day)),
        );
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

  LocalHabitRecord _recordDtoToLocal(
    Map<String, dynamic> map,
    String habitId,
  ) => LocalHabitRecord()
    ..serverId = map['id'] as String?
    ..habitId = habitId
    ..recordDate = _parseDate(map['recordDate'])
    ..value = (map['value'] as num?)?.toDouble()
    ..completed = map['completed'] as bool?
    ..createdAt = _parseDateTime(map['createdAt'])
    ..updatedAt = _parseDateTime(map['updatedAt']);
}
