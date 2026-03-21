import 'package:hive/hive.dart';

part 'workout.g.dart';

@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String note;

  @HiveField(3)
  List<String>? notes;

  @HiveField(4)
  String? profileId;

  @HiveField(5)
  String? description;

  @HiveField(6)
  List<String>? tags;

  Workout({
    required this.id,
    required this.name,
    this.note = '',
    this.notes,
    this.profileId,
    this.description,
    this.tags,
  });

  List<String> get allNotes => notes ?? (note.isNotEmpty ? [note] : []);
}
