import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}
class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final workout = Provider.of<WorkoutProvider>(context, listen: false)
        .getWorkoutById(widget.workoutId);
    if (workout != null) {
      _descriptionController.text = workout.description ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final workout = provider.getWorkoutById(widget.workoutId);
        if (workout == null) return const Scaffold(body: Center(child: Text('Not found')));

        return Scaffold(
          appBar: AppBar(title: Text(workout.name)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Workout Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add form tips, equipment settings, etc...',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      provider.updateWorkoutDescription(workout.id, value.trim());
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Workout Tags',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ...(workout.tags ?? []).map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            onDeleted: () {
                              final newTags = List<String>.from(workout.tags!)
                                ..remove(tag);
                              provider.updateWorkoutTags(workout.id, newTags);
                            },
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          )),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: '+ Add tag',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              final newTags =
                                  List<String>.from(workout.tags ?? [])
                                    ..add(value.trim());
                              provider.updateWorkoutTags(
                                  workout.id, newTags.toSet().toList());
                              _tagController.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Workout Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  // Add Note Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Add a new note...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              provider.addNoteToWorkout(workout.id, value.trim());
                              _noteController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (_noteController.text.trim().isNotEmpty) {
                            provider.addNoteToWorkout(
                                workout.id, _noteController.text.trim());
                            _noteController.clear();
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Notes List
                  ...workout.allNotes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final noteText = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notes, size: 16, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                noteText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              onPressed: () => _showEditNoteItemDialog(
                                  context, provider, workout.id, index, noteText),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              onPressed: () =>
                                  provider.deleteNoteFromWorkout(workout.id, index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text('Recent History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  _buildHistoryList(provider, workout.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditNoteItemDialog(BuildContext context, WorkoutProvider provider, String workoutId, int index, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Note text'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              provider.updateNoteInWorkout(workoutId, index, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(WorkoutProvider provider, String workoutId) {
    // Collect all sets for this workout across all sessions
    final Map<DateTime, List<dynamic>> historyByDate = {};
    
    for (var session in provider.sessions) {
      for (var exercise in session.exercises) {
        if (exercise.workoutId == workoutId) {
          for (var set in exercise.sets) {
            final DateTime rawDate = set.date ?? DateTime.now();
            final dateKey = DateTime(rawDate.year, rawDate.month, rawDate.day);
            historyByDate.putIfAbsent(dateKey, () => []).add(set);
          }
        }
      }
    }

    if (historyByDate.isEmpty) {
      return const Center(child: Text('No history found.'));
    }

    final now = DateTime.now();
    final twoWeeksAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14));
    
    final sortedDates = historyByDate.keys
        .where((date) => date.isAfter(twoWeeksAgo) || date.isAtSameMomentAs(twoWeeksAgo))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final sets = historyByDate[date]!;
        
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...sets.asMap().entries.map((e) {
                  final setIndex = e.key + 1;
                  final set = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text('Set $setIndex:'),
                        const SizedBox(width: 16),
                        Text('${set.weight} kg x ${set.reps} reps', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
