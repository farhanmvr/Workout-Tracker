import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/workout.dart';
import '../models/session.dart';
import '../models/body_weight.dart';

import 'package:flutter/material.dart';

class BackupService {
  static Future<void> exportBackup(BuildContext context) async {
    final workoutsBox = Hive.box<Workout>('workouts');
    final sessionsBox = Hive.box<WorkoutSession>('sessions');
    final weightBox = Hive.box<BodyWeightRecord>('bodyWeights');
    final settingsBox = Hive.box('settings');

    final data = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'workouts': workoutsBox.values.map((e) => {
        'id': e.id,
        'name': e.name,
        'note': e.note,
      }).toList(),
      'sessions': sessionsBox.values.map((s) => {
        'id': s.id,
        'name': s.name,
        'exercises': s.exercises.map((e) => {
          'id': e.id,
          'workoutId': e.workoutId,
          'sets': e.sets.map((set) => {
            'weight': set.weight,
            'reps': set.reps,
            'date': set.date?.toIso8601String(),
          }).toList(),
        }).toList(),
      }).toList(),
      'bodyWeights': weightBox.values.map((w) => {
        'id': w.id,
        'weight': w.weight,
        'date': w.date.toIso8601String(),
      }).toList(),
      'settings': {
        'userHeight': settingsBox.get('userHeight'),
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/workout_tracker_backup.json');
    await file.writeAsString(jsonString);

    // Get the render box for iPad sharing
    final box = context.findRenderObject() as RenderBox?;
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Workout Tracker Backup',
      text: 'Here is my workout tracker data backup.',
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);

        if (data['version'] != 1) {
          throw Exception('Unsupported backup version');
        }

        // Clear existing data
        await Hive.box<Workout>('workouts').clear();
        await Hive.box<WorkoutSession>('sessions').clear();
        await Hive.box<BodyWeightRecord>('bodyWeights').clear();
        await Hive.box('settings').clear();

        // Restore Workouts
        final workoutsBox = Hive.box<Workout>('workouts');
        if (data['workouts'] != null) {
          for (var w in data['workouts']) {
            await workoutsBox.put(w['id'], Workout(
              id: w['id'], 
              name: w['name'], 
              note: w['note'] ?? ''
            ));
          }
        }

        // Restore Sessions
        final sessionsBox = Hive.box<WorkoutSession>('sessions');
        if (data['sessions'] != null) {
          for (var s in data['sessions']) {
            await sessionsBox.put(s['id'], WorkoutSession(
              id: s['id'],
              name: s['name'],
              exercises: (s['exercises'] as List).map((e) => SessionExercise(
                id: e['id'],
                workoutId: e['workoutId'],
                sets: (e['sets'] as List).map((set) => SessionSet(
                  weight: (set['weight'] as num).toDouble(),
                  reps: set['reps'],
                  date: set['date'] != null ? DateTime.parse(set['date']) : null,
                )).toList(),
              )).toList(),
            ));
          }
        }

        // Restore Body Weights
        final weightBox = Hive.box<BodyWeightRecord>('bodyWeights');
        if (data['bodyWeights'] != null) {
          for (var w in data['bodyWeights']) {
            await weightBox.put(w['id'], BodyWeightRecord(
              id: w['id'],
              weight: (w['weight'] as num).toDouble(),
              date: DateTime.parse(w['date']),
            ));
          }
        }

        // Restore Settings
        final settingsBox = Hive.box('settings');
        if (data['settings'] != null) {
          await settingsBox.put('userHeight', data['settings']['userHeight']);
        }

        return true;
      }
    } catch (e) {
      rethrow;
    }
    return false;
  }
}
