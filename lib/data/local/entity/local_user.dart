import 'package:isar/isar.dart';

part 'local_user.g.dart';

@collection
class LocalUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  String? email;
  String? displayName;
  DateTime? createdAt;
  DateTime? updatedAt;
}
