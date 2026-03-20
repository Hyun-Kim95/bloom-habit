import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import '../local/entity/local_habit_record.dart';
import '../local/entity/local_habit.dart';
import '../local/entity/local_user.dart';
import '../../core/network/api_endpoints.dart';

/// Server <-> local sync repository.
/// Initial flow: full pull after login, then local upsert.
class SyncRepository {
  SyncRepository({
    required Dio dio,
    required Future<Isar> isarFuture,
  })  : _dio = dio,
        _isarFuture = isarFuture;

  final Dio _dio;
  final Future<Isar> _isarFuture;

  /// Incremental pull from `since` (ISO timestamp). Null means full pull.
  Future<void> pull({String? since}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.sync,
      queryParameters: since != null ? {'since': since} : null,
    );
    if (res.data == null) return;
    final isar = await _isarFuture;

    await isar.writeTxn(() async {
      final users = res.data!['users'] as List<dynamic>?;
      if (users != null) {
        for (final u in users) {
          final map = u as Map<String, dynamic>;
          final local = LocalUser()
            ..serverId = map['id'] as String?
            ..email = map['email'] as String?
            ..displayName = map['displayName'] as String?
            ..createdAt = _parseDateTime(map['createdAt'])
            ..updatedAt = _parseDateTime(map['updatedAt']);
          final existing = await isar.localUsers.getByServerId(local.serverId);
          if (existing != null) local.id = existing.id;
          await isar.localUsers.put(local);
        }
      }

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
            if (existing != null) local.id = existing.id;
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
}
