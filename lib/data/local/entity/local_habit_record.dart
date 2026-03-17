import 'package:isar/isar.dart';

part 'local_habit_record.g.dart';

@collection
class LocalHabitRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  String? habitId;
  DateTime? recordDate;
  double? value;
  bool? completed;
  DateTime? createdAt;
  DateTime? updatedAt;
}
