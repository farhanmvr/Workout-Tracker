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
import '../widgets/app_bar_action_button.dart'; // Added import

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  String _workoutSearchQuery = ''; // Existing
  String _exerciseSearchQuery = ''; // Added
  bool _isSearching = false; // Added
  final _searchController = TextEditingController(); // Added
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _searchController.dispose(); // Added
    super.dispose();
  }

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

        // Filter exercises based on search query and tag
        final filteredExercises = session.exercises.where((exercise) {
          final workoutObj = provider.getWorkoutById(exercise.workoutId);
          final matchesSearch = _exerciseSearchQuery.isEmpty ||
              (workoutObj?.name
                      .toLowerCase()
                      .contains(_exerciseSearchQuery.toLowerCase()) ??
                  false);
          final matchesTag = _selectedTags.isEmpty ||
              (workoutObj?.tags?.any((tag) => _selectedTags.contains(tag)) ??
                  false);
          return matchesSearch && matchesTag;
        }).toList();

        final sessionTags = session.exercises
            .map((e) => provider.getWorkoutById(e.workoutId)?.tags ?? [])
            .expand((t) => t)
            .toSet()
            .toList()
          ..sort();


        return Scaffold(
          appBar: AppBar(
            title: _isSearching // Modified AppBar title
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search exercises...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _exerciseSearchQuery = value;
                      });
                    },
                  )
                : Text(session.name),
            actions: [
              IconButton( // Added search icon button
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _exerciseSearchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              AppBarActionButton( // Changed to AppBarActionButton
                onPressed: () => _showSelectWorkoutDialog(context, provider),
                icon: Icons.add,
                tooltip: 'Add Exercise',
              ),
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
              : Column(
                  children: [
                    if (sessionTags.isNotEmpty)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sessionTags.length + 1,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final tag = isAll ? null : sessionTags[index - 1];
                            final isSelected = isAll
                                ? _selectedTags.isEmpty
                                : _selectedTags.contains(tag);

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  isAll ? 'All' : tag!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (isAll) {
                                      _selectedTags.clear();
                                    } else {
                                      if (selected) {
                                        _selectedTags.add(tag!);
                                      } else {
                                        _selectedTags.remove(tag!);
                                      }
                                    }
                                  });
                                },
                                backgroundColor: Colors.transparent,
                                selectedColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: filteredExercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isSearching || _selectedTags.isNotEmpty
                                        ? Icons.search_off
                                        : Icons.fitness_center_outlined,
                                    size: 64,
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No exercises match your criteria',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderExercisesInSession(
                      widget.sessionId,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
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
                                if (workoutObj?.tags != null &&
                                    workoutObj!.tags!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: workoutObj!.tags!
                                          .map((tag) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                if (workoutObj != null &&
                                    workoutObj.allNotes.isNotEmpty)
                                  ...workoutObj.allNotes.map((note) => Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.notes,
                                              size: 11,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                note,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                if (recentSet != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${recentSet.weight} kg x ${recentSet.reps} reps',
                                      style: TextStyle(
                                        color: isDoneToday
                                            ? Colors.green
                                            : Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            children: [
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
                                            Icons.settings_outlined,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Manage workout',
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
              ),
            ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Add Exercise',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search workouts...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _workoutSearchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<WorkoutProvider>(
                    builder: (context, workoutProvider, child) {
                      final workouts = workoutProvider.workouts.where((w) {
                        return w.name.toLowerCase().contains(_workoutSearchQuery);
                      }).toList();

                      if (workouts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No workouts match "$_workoutSearchQuery"',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          final initials = workout.name.isNotEmpty
                              ? workout.name[0].toUpperCase()
                              : '?';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumCard(
                              onTap: () {
                                workoutProvider.addExerciseToSession(
                                  widget.sessionId,
                                  workout.id,
                                );
                                Navigator.pop(context);
                              },
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  workout.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  workout.allNotes.isNotEmpty
                                      ? workout.allNotes.last
                                      : 'No notes',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
