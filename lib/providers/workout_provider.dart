import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/session.dart';

class WorkoutProvider extends ChangeNotifier {
  late Box<Workout> _workoutBox;
  late Box<WorkoutSession> _sessionBox;
  
  late Box _settingsBox;
  String? _activeProfileId;

  void updateProfile(String? profileId) {
    if (_activeProfileId != profileId) {
      _activeProfileId = profileId;
      notifyListeners();
    }
  }
  
  List<Workout> get workouts {
    final list = _workoutBox.values.where((w) {
      return w.profileId == _activeProfileId || (w.profileId == null && _activeProfileId == 'default_main');
    }).toList();
    final orderKey = 'workoutIdOrder_$_activeProfileId';
    final order = _settingsBox.get(orderKey) as List?;
    if (order != null) {
      final orderMap = {for (int i = 0; i < order.length; i++) order[i]: i};
      list.sort((a, b) {
        final posA = orderMap[a.id] ?? 999;
        final posB = orderMap[b.id] ?? 999;
        return posA.compareTo(posB);
      });
    }
    return list;
  }

  List<WorkoutSession> get sessions {
    final list = _sessionBox.values.where((s) {
      return s.profileId == _activeProfileId || (s.profileId == null && _activeProfileId == 'default_main');
    }).toList();
    final orderKey = 'sessionIdOrder_$_activeProfileId';
    final order = _settingsBox.get(orderKey) as List?;
    if (order != null) {
      final orderMap = {for (int i = 0; i < order.length; i++) order[i]: i};
      list.sort((a, b) {
        final posA = orderMap[a.id] ?? 999;
        final posB = orderMap[b.id] ?? 999;
        return posA.compareTo(posB);
      });
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    _workoutBox = Hive.box<Workout>('workouts');
    _sessionBox = Hive.box<WorkoutSession>('sessions');
    _settingsBox = Hive.box('settings');
    _initialized = true;
    notifyListeners();
  }

  // Workouts
  Future<void> addWorkout(String name,
      {String note = '', String description = '', List<String>? tags}) async {
    final workout = Workout(
      id: const Uuid().v4(),
      name: name,
      notes: note.isNotEmpty ? [note] : [],
      profileId: _activeProfileId,
      description: description,
      tags: tags,
    );
    await _workoutBox.put(workout.id, workout);


    
    // Supplement order
    final orderKey = 'workoutIdOrder_$_activeProfileId';
    final order = List<String>.from(_settingsBox.get(orderKey, defaultValue: []) as List);
    order.add(workout.id);
    await _settingsBox.put(orderKey, order);
    
    notifyListeners();
  }

  Future<void> addNoteToWorkout(String workoutId, String noteText) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null) {
      final notes = List<String>.from(workout.notes ?? (workout.note.isNotEmpty ? [workout.note] : []));
      notes.add(noteText);
      workout.notes = notes;
      workout.note = ''; // Clear old single note
      await workout.save();
      notifyListeners();
    }
  }

  Future<void> updateNoteInWorkout(String workoutId, int index, String newText) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null && workout.notes != null && index < workout.notes!.length) {
      final notes = List<String>.from(workout.notes!);
      notes[index] = newText;
      workout.notes = notes;
      await workout.save();
      notifyListeners();
    }
  }

  Future<void> deleteNoteFromWorkout(String workoutId, int index) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null && workout.notes != null && index < workout.notes!.length) {
      final notes = List<String>.from(workout.notes!);
      notes.removeAt(index);
      workout.notes = notes;
      await workout.save();
      notifyListeners();
    }
  }

  Future<void> reorderWorkouts(int oldIndex, int newIndex) async {
    final currentOrder = workouts.map((e) => e.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = currentOrder.removeAt(oldIndex);
    currentOrder.insert(newIndex, item);
    final orderKey = 'workoutIdOrder_$_activeProfileId';
    await _settingsBox.put(orderKey, currentOrder);
    notifyListeners();
  }

  Future<void> updateWorkoutName(String workoutId, String newName) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null) {
      workout.name = newName;
      await workout.save();
      notifyListeners();
    }
  }

  Future<void> updateWorkoutDescription(String workoutId, String newDescription) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null) {
      workout.description = newDescription;
      await workout.save();
      notifyListeners();
    }
  }

  Future<void> updateWorkoutTags(String workoutId, List<String> newTags) async {
    final workout = _workoutBox.get(workoutId);
    if (workout != null) {
      workout.tags = newTags;
      await workout.save();
      notifyListeners();
    }
  }

  List<String> get allAvailableTags {
    final Set<String> tags = {};
    for (var workout in workouts) {
      if (workout.tags != null) {
        tags.addAll(workout.tags!);
      }
    }
    return tags.toList()..sort();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutBox.delete(workoutId);
    // Remove from order
    final orderKey = 'workoutIdOrder_$_activeProfileId';
    final order = List<String>.from(_settingsBox.get(orderKey, defaultValue: []) as List);
    order.remove(workoutId);
    await _settingsBox.put(orderKey, order);
    notifyListeners();
  }

  // Sessions
  Future<void> addSession(String name) async {
    final session = WorkoutSession(
      id: const Uuid().v4(),
      name: name,
      exercises: [],
      profileId: _activeProfileId,
    );
    await _sessionBox.put(session.id, session);
    
    // Supplement order
    final orderKey = 'sessionIdOrder_$_activeProfileId';
    final order = List<String>.from(_settingsBox.get(orderKey, defaultValue: []) as List);
    order.add(session.id);
    await _settingsBox.put(orderKey, order);
    
    notifyListeners();
  }

  Future<void> reorderSessions(int oldIndex, int newIndex) async {
    final currentOrder = sessions.map((e) => e.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = currentOrder.removeAt(oldIndex);
    currentOrder.insert(newIndex, item);
    final orderKey = 'sessionIdOrder_$_activeProfileId';
    await _settingsBox.put(orderKey, currentOrder);
    notifyListeners();
  }

  Future<void> updateSessionName(String sessionId, String newName) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      session.name = newName;
      await session.save();
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionBox.delete(sessionId);
    // Remove from order
    final orderKey = 'sessionIdOrder_$_activeProfileId';
    final order = List<String>.from(_settingsBox.get(orderKey, defaultValue: []) as List);
    order.remove(sessionId);
    await _settingsBox.put(orderKey, order);
    notifyListeners();
  }

  Future<void> addExerciseToSession(String sessionId, String workoutId) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      session.exercises.add(SessionExercise(
        id: const Uuid().v4(),
        workoutId: workoutId,
        sets: [],
      ));
      await session.save();
      notifyListeners();
    }
  }

  Future<void> reorderExercisesInSession(String sessionId, int oldIndex, int newIndex) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = session.exercises.removeAt(oldIndex);
      session.exercises.insert(newIndex, item);
      await session.save();
      notifyListeners();
    }
  }

  Future<void> addSetToExercise(String sessionId, String exerciseId, double weight, int reps, DateTime date, {bool isEachSide = false}) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      final exerciseIndex = session.exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        session.exercises[exerciseIndex].sets.add(SessionSet(
          weight: weight,
          reps: reps,
          date: date,
          isEachSide: isEachSide,
        ));
        await session.save();
        notifyListeners();
      }
    }
  }

  Future<void> updateSetInExercise(String sessionId, String exerciseId, SessionSet oldSet, double newWeight, int newReps, DateTime newDate, {bool newIsEachSide = false}) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      final exerciseIndex = session.exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final setIndex = session.exercises[exerciseIndex].sets.indexOf(oldSet);
        if (setIndex != -1) {
          final targetSet = session.exercises[exerciseIndex].sets[setIndex];
          targetSet.weight = newWeight;
          targetSet.reps = newReps;
          targetSet.date = newDate;
          targetSet.isEachSide = newIsEachSide;
          await session.save();
          notifyListeners();
        }
      }
    }
  }

  Future<void> removeSetFromExercise(String sessionId, String exerciseId, SessionSet set) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      final exerciseIndex = session.exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        session.exercises[exerciseIndex].sets.remove(set);
        await session.save();
        notifyListeners();
      }
    }
  }

  Future<void> removeExerciseFromSession(String sessionId, String exerciseId) async {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      session.exercises.removeWhere((e) => e.id == exerciseId);
      await session.save();
      notifyListeners();
    }
  }

  // Helpers
  Workout? getWorkoutById(String id) {
    return _workoutBox.get(id);
  }
}
