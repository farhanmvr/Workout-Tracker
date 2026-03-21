import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import '../models/session.dart';
import '../models/body_weight.dart';

class ProfileProvider with ChangeNotifier {
  late Box<Profile> _profileBox;
  late Box _settingsBox;

  List<Profile> _profiles = [];
  String? _activeProfileId;

  List<Profile> get profiles => _profiles;

  Profile? get activeProfile {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  String? get activeProfileId => _activeProfileId;

  Future<void> init() async {
    _profileBox = Hive.box<Profile>('profiles');
    _settingsBox = Hive.box('settings');

    _profiles = _profileBox.values.toList();
    _activeProfileId = _settingsBox.get('activeProfileId');

    // Ensure at least one profile exists
    if (_profiles.isEmpty) {
      final defaultProfile = Profile(
        id: 'default_main',
        name: 'Main Profile',
        createdAt: DateTime.now(),
      );
      await _profileBox.put(defaultProfile.id, defaultProfile);
      _profiles = [defaultProfile];
      _activeProfileId = defaultProfile.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    } else if (_activeProfileId == null ||
        !(_profiles.any((p) => p.id == _activeProfileId))) {
      _activeProfileId = _profiles.first.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    }

    notifyListeners();
  }

  Future<void> addProfile(String name) async {
    final newProfile = Profile(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _profileBox.put(newProfile.id, newProfile);
    _profiles = _profileBox.values.toList();
    notifyListeners();
  }

  Future<void> cloneProfile(String originalId, String newName) async {
    final newId = const Uuid().v4();
    final newProfile = Profile(
      id: newId,
      name: newName,
      createdAt: DateTime.now(),
    );
    await _profileBox.put(newId, newProfile);
    _profiles = _profileBox.values.toList();

    // 1. Copy Workouts
    final workoutBox = Hive.box<Workout>('workouts');
    final originalWorkouts = workoutBox.values.where((w) {
      return w.profileId == originalId ||
          (w.profileId == null && originalId == 'default_main');
    }).toList();

    final Map<String, String> workoutIdMapping = {};
    for (var oldWorkout in originalWorkouts) {
      final newWorkoutId = const Uuid().v4();
      workoutIdMapping[oldWorkout.id] = newWorkoutId;
      final clonedWorkout = Workout(
        id: newWorkoutId,
        name: oldWorkout.name,
        note: oldWorkout.note,
        notes: oldWorkout.notes != null ? List<String>.from(oldWorkout.notes!) : null,
        profileId: newId,
        description: oldWorkout.description,
        tags: oldWorkout.tags != null ? List<String>.from(oldWorkout.tags!) : null,
      );
      await workoutBox.put(newWorkoutId, clonedWorkout);
    }

    // Copy workout ordering
    final workoutOrderKey = 'workoutIdOrder_$originalId';
    final workoutOrder = _settingsBox.get(workoutOrderKey) as List?;
    if (workoutOrder != null) {
      final newOrder = workoutOrder
          .map((id) => workoutIdMapping[id])
          .whereType<String>()
          .toList();
      await _settingsBox.put('workoutIdOrder_$newId', newOrder);
    }

    // 2. Copy Sessions
    final sessionBox = Hive.box<WorkoutSession>('sessions');
    final originalSessions = sessionBox.values.where((s) {
      return s.profileId == originalId ||
          (s.profileId == null && originalId == 'default_main');
    }).toList();

    final Map<String, String> sessionIdMapping = {};
    for (var oldSession in originalSessions) {
      final newSessionId = const Uuid().v4();
      sessionIdMapping[oldSession.id] = newSessionId;

      final clonedExercises = oldSession.exercises.map((ex) {
        return SessionExercise(
          id: const Uuid().v4(),
          workoutId: workoutIdMapping[ex.workoutId] ?? ex.workoutId,
          sets: ex.sets
              .map((s) => SessionSet(
                    weight: s.weight,
                    reps: s.reps,
                    date: s.date,
                  ))
              .toList(),
        );
      }).toList();

      final clonedSession = WorkoutSession(
        id: newSessionId,
        name: oldSession.name,
        exercises: clonedExercises,
        profileId: newId,
      );
      await sessionBox.put(newSessionId, clonedSession);
    }

    // Copy session ordering
    final sessionOrderKey = 'sessionIdOrder_$originalId';
    final sessionOrder = _settingsBox.get(sessionOrderKey) as List?;
    if (sessionOrder != null) {
      final newOrder = sessionOrder
          .map((id) => sessionIdMapping[id])
          .whereType<String>()
          .toList();
      await _settingsBox.put('sessionIdOrder_$newId', newOrder);
    }

    // 3. Copy Weight Records
    final weightBox = Hive.box<BodyWeightRecord>('bodyWeights');
    final originalWeights = weightBox.values.where((w) {
      return w.profileId == originalId ||
          (w.profileId == null && originalId == 'default_main');
    }).toList();

    for (var oldWeight in originalWeights) {
      final clonedWeight = BodyWeightRecord(
        id: const Uuid().v4(),
        weight: oldWeight.weight,
        date: oldWeight.date,
        profileId: newId,
      );
      await weightBox.put(clonedWeight.id, clonedWeight);
    }

    // 4. Copy Settings (Height)
    final height = _settingsBox.get('userHeight_$originalId');
    if (height != null) {
      await _settingsBox.put('userHeight_$newId', height);
    }

    notifyListeners();
  }

  Future<void> updateProfile(String id, String newName) async {
    final profile = _profileBox.get(id);
    if (profile != null) {
      profile.name = newName;
      await profile.save();
      _profiles = _profileBox.values.toList();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return; // Prevent deleting the last profile

    await _profileBox.delete(id);
    _profiles = _profileBox.values.toList();

    if (_activeProfileId == id) {
      _activeProfileId = _profiles.first.id;
      await _settingsBox.put('activeProfileId', _activeProfileId);
    }

    notifyListeners();
  }

  Future<void> setActiveProfile(String id) async {
    if (_activeProfileId == id) return;
    _activeProfileId = id;
    await _settingsBox.put('activeProfileId', id);
    notifyListeners();
  }
}
