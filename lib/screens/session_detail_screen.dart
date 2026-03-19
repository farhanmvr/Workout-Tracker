import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/session.dart';
import '../utils/dialogs.dart';
import 'workout_detail_screen.dart';
import '../widgets/premium_card.dart';

import '../services/export_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        // Find session
        WorkoutSession? session;
        try {
          session = provider.sessions.firstWhere(
            (s) => s.id == widget.sessionId,
          );
        } catch (e) {
          session = null;
        }

        if (session == null) {
          return const Scaffold(body: Center(child: Text('Session not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Export PDF',
                onPressed: () {
                  final workoutMap = {for (var w in provider.workouts) w.id: w};
                  ExportService.exportSessionToPdf(
                    context,
                    session!,
                    workoutMap,
                  );
                },
              ),
            ],
          ),
          body: session.exercises.isEmpty
              ? const Center(
                  child: Text('No exercises added to this session yet.'),
                )
              : ReorderableListView.builder(
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderExercisesInSession(
                      widget.sessionId,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemCount: session.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = session!.exercises[index];
                    final workoutObj = provider.getWorkoutById(
                      exercise.workoutId,
                    );
                    final workoutName = workoutObj?.name ?? 'Unknown Workout';

                    final isDoneToday = exercise.sets.any((set) {
                      final d = set.date ?? DateTime.now();
                      final now = DateTime.now();
                      return d.year == now.year &&
                          d.month == now.month &&
                          d.day == now.day;
                    });

                    SessionSet? recentSet;
                    if (exercise.sets.isNotEmpty) {
                      final sorted = List<SessionSet>.from(exercise.sets)
                        ..sort(
                          (a, b) => (b.date ?? DateTime.now()).compareTo(
                            a.date ?? DateTime.now(),
                          ),
                        );
                      recentSet = sorted.first;
                    }

                    return PremiumCard(
                      key: ValueKey(exercise.id),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Slidable(
                        key: ValueKey(exercise.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                final confirm = await showDeleteConfirmation(
                                  context,
                                  'Exercise',
                                );
                                if (confirm == true) {
                                  provider.removeExerciseFromSession(
                                    widget.sessionId,
                                    exercise.id,
                                  );
                                }
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Remove',
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    workoutName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isDoneToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'DONE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (recentSet != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${recentSet.weight} kg x ${recentSet.reps} reps',
                                      style: TextStyle(
                                        color: isDoneToday
                                            ? Colors.green
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (workoutObj != null &&
                                    workoutObj.allNotes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.notes,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            workoutObj.allNotes.first,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            children: [
                              if (workoutObj != null &&
                                  workoutObj.allNotes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: workoutObj.allNotes
                                        .map(
                                          (note) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    note,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              if (workoutObj != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkoutDetailScreen(
                                                workoutId: workoutObj.id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note,
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          workoutObj.allNotes.isEmpty
                                              ? 'Add a note...'
                                              : 'Manage notes',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showAddSetDialog(context, exercise.id),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'LOG NEW SET',
                                    style: TextStyle(
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      45,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              if (exercise.sets.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'SET',
                                          style: _setLabelStyle(context),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'WEIGHT',
                                          style: _setLabelStyle(context),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'REPS',
                                          style: _setLabelStyle(context),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'DATE',
                                          style: _setLabelStyle(context),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Divider(height: 1),
                              if (exercise.sets.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No sets recorded.'),
                                )
                              else
                                ...() {
                                  final sortedSets =
                                      List<SessionSet>.from(exercise.sets)
                                        ..sort(
                                          (a, b) => (b.date ?? DateTime.now())
                                              .compareTo(
                                                a.date ?? DateTime.now(),
                                              ),
                                        );

                                  final displaySets = sortedSets
                                      .take(5)
                                      .toList();
                                  final int extraCount = sortedSets.length - 5;

                                  final List<Widget> setWidgets = displaySets
                                      .asMap()
                                      .entries
                                      .map<Widget>((entry) {
                                        final int index = entry.key;
                                        final SessionSet set = entry.value;
                                        final date = set.date ?? DateTime.now();
                                        final setNumber =
                                            sortedSets.length - index;

                                        return Slidable(
                                          key: ValueKey(set.hashCode),
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            extentRatio: 0.5,
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) =>
                                                    _showEditSetDialog(
                                                      context,
                                                      exercise.id,
                                                      set,
                                                    ),
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                icon: Icons.edit,
                                                label: 'Edit',
                                              ),
                                              SlidableAction(
                                                onPressed: (context) async {
                                                  final confirm =
                                                      await showDeleteConfirmation(
                                                        context,
                                                        'Set',
                                                      );
                                                  if (confirm == true) {
                                                    provider
                                                        .removeSetFromExercise(
                                                          widget.sessionId,
                                                          exercise.id,
                                                          set,
                                                        );
                                                  }
                                                },
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                icon: Icons.delete,
                                                label: 'Delete',
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '$setNumber',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    '${set.weight} kg',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${set.reps}',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    "${DateFormat('d MMM').format(date)} '${DateFormat('yy').format(date)}",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      })
                                      .toList();

                                  if (extraCount > 0) {
                                    setWidgets.add(
                                      ListTile(
                                        title: Center(
                                          child: Text(
                                            'Show $extraCount more (Full History)',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  WorkoutDetailScreen(
                                                    workoutId:
                                                        exercise.workoutId,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return setWidgets;
                                }(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showSelectWorkoutDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        );
      },
    );
  }

  void _showAddSetDialog(BuildContext context, String exerciseId) {
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Set'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg/lbs)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      final w = double.tryParse(weightController.text.trim());
                      final r = int.tryParse(repsController.text.trim());
                      if (w != null && r != null) {
                        Provider.of<WorkoutProvider>(
                          context,
                          listen: false,
                        ).addSetToExercise(
                          widget.sessionId,
                          exerciseId,
                          w,
                          r,
                          selectedDate,
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      const Spacer(),
                      TextButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final w = double.tryParse(weightController.text.trim());
                    final r = int.tryParse(repsController.text.trim());
                    if (w != null && r != null) {
                      Provider.of<WorkoutProvider>(
                        context,
                        listen: false,
                      ).addSetToExercise(
                        widget.sessionId,
                        exerciseId,
                        w,
                        r,
                        selectedDate,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSetDialog(
    BuildContext context,
    String exerciseId,
    SessionSet set,
  ) {
    final weightController = TextEditingController(text: set.weight.toString());
    final repsController = TextEditingController(text: set.reps.toString());
    DateTime selectedDate = set.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Set'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg/lbs)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      final w = double.tryParse(weightController.text.trim());
                      final r = int.tryParse(repsController.text.trim());
                      if (w != null && r != null) {
                        Provider.of<WorkoutProvider>(
                          context,
                          listen: false,
                        ).updateSetInExercise(
                          widget.sessionId,
                          exerciseId,
                          set,
                          w,
                          r,
                          selectedDate,
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      const Spacer(),
                      TextButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final w = double.tryParse(weightController.text.trim());
                    final r = int.tryParse(repsController.text.trim());
                    if (w != null && r != null) {
                      Provider.of<WorkoutProvider>(
                        context,
                        listen: false,
                      ).updateSetInExercise(
                        widget.sessionId,
                        exerciseId,
                        set,
                        w,
                        r,
                        selectedDate,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectWorkoutDialog(
    BuildContext context,
    WorkoutProvider provider,
  ) {
    if (provider.workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a workout in the Workouts tab first!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Workout'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.workouts.length,
            itemBuilder: (context, index) {
              final workout = provider.workouts[index];
              return ListTile(
                title: Text(workout.name),
                onTap: () {
                  provider.addExerciseToSession(widget.sessionId, workout.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle _setLabelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      letterSpacing: 1.2,
    );
  }
}
