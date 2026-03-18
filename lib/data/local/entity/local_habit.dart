import 'package:isar/isar.dart';

part 'local_habit.g.dart';

@collection
class LocalHabit {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  String? userId;
  String? name;
  String? category;
  String? goalType;
  double? goalValue;
  DateTime? startDate;
  String? colorHex;
  String? iconName;
  /// 습관별 리마인더 알림 (로컬 전용, 서버 미동기화)
  bool? reminderEnabled;
  int? reminderHour;
  int? reminderMinute;
  DateTime? archivedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
}
