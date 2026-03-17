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
  DateTime? archivedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
}
