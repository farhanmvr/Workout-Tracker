import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/body_weight.dart';

class StatsProvider extends ChangeNotifier {
  late Box<BodyWeightRecord> _weightBox;
  late Box _settingsBox;
  String? _activeProfileId;

  List<BodyWeightRecord> get weightHistory => _weightBox.values
      .where((w) =>
          w.profileId == _activeProfileId ||
          (w.profileId == null && _activeProfileId == 'default_main'))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  double? get height =>
      _settingsBox.get('userHeight_$_activeProfileId');

  void updateProfile(String? profileId) {
    if (_activeProfileId != profileId) {
      _activeProfileId = profileId;
      notifyListeners();
    }
  }

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    _weightBox = Hive.box<BodyWeightRecord>('bodyWeights');
    _settingsBox = Hive.box('settings');
    _initialized = true;
    notifyListeners();
  }

  Future<void> addWeight(double weight, DateTime date) async {
    final record = BodyWeightRecord(
      id: const Uuid().v4(),
      weight: weight,
      date: date,
      profileId: _activeProfileId,
    );
    await _weightBox.put(record.id, record);
    notifyListeners();
  }

  Future<void> updateWeight(String id, double weight, DateTime date) async {
    final record = _weightBox.get(id);
    if (record != null) {
      record.weight = weight;
      record.date = date;
      await record.save();
      notifyListeners();
    }
  }

  Future<void> deleteWeight(String id) async {
    await _weightBox.delete(id);
    notifyListeners();
  }

  Future<void> setHeight(double cm) async {
    await _settingsBox.put('userHeight_$_activeProfileId', cm);
    notifyListeners();
  }

  double? get currentBmi {
    if (height == null || height == 0 || weightHistory.isEmpty) return null;
    final latestWeight = weightHistory.last.weight;
    final hMeters = height! / 100;
    return latestWeight / (hMeters * hMeters);
  }
}
