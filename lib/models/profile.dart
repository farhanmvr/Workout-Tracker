import 'package:hive/hive.dart';

part 'profile.g.dart';

@HiveType(typeId: 5)
class Profile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
