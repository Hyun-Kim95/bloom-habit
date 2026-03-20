import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'entity/local_habit_record.dart';
import 'entity/local_habit.dart';
import 'entity/local_user.dart';

const _schemas = [
  LocalUserSchema,
  LocalHabitSchema,
  LocalHabitRecordSchema,
];

/// Isar instance initialized once at app start.
Future<Isar> openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    _schemas,
    directory: dir.path,
    name: 'bloom_habit',
  );
}
