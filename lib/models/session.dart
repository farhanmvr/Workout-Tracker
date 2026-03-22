import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class SessionSet {
  @HiveField(0)
  double weight;

  @HiveField(1)
  int reps;

  @HiveField(2)
  DateTime? date;

  @HiveField(3)
  bool? isEachSide;

  SessionSet({
    required this.weight,
    required this.reps,
    this.date,
    this.isEachSide = false,
  });
}

@HiveType(typeId: 2)
class SessionExercise {
  @HiveField(0)
  String id;

  @HiveField(1)
  String workoutId;

  @HiveField(2)
  List<SessionSet> sets;

  SessionExercise({
    required this.id,
    required this.workoutId,
    required this.sets,
  });
}

@HiveType(typeId: 3)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // e.g. Push, Pull, Legs

  // Field 2 (date) removed.

  @HiveField(3)
  List<SessionExercise> exercises;

  @HiveField(4)
  String? profileId;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.exercises,
    this.profileId,
  });
}
