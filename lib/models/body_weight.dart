import 'package:hive/hive.dart';

part 'body_weight.g.dart';

@HiveType(typeId: 4)
class BodyWeightRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double weight;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? profileId;

  BodyWeightRecord({
    required this.id,
    required this.weight,
    required this.date,
    this.profileId,
  });
}
