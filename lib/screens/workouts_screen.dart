import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../utils/dialogs.dart';
import 'profiles_screen.dart';
import '../providers/profile_provider.dart';
import 'workout_detail_screen.dart';
import '../widgets/premium_card.dart';
import '../widgets/app_bar_action_button.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearching = false;
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search workouts...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text('Workouts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          AppBarActionButton(
            onPressed: () => _showAddWorkoutDialog(context),
            icon: Icons.add,
            tooltip: 'Add Workout',
          ),
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilesScreen(),
                    ),
                  );
                },
                icon: const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 16),
                ),
                label: Text(
                  profileProvider.activeProfile?.name ?? 'Profile',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final allTags = provider.allAvailableTags;
          final workouts = provider.workouts.where((w) {
            final matchesSearch = w.name.toLowerCase().contains(_searchQuery);
            final matchesTag = _selectedTags.isEmpty ||
                (w.tags != null &&
                    _selectedTags.any((tag) => w.tags!.contains(tag)));
            return matchesSearch && matchesTag;
          }).toList();

          return Column(
            children: [
              if (allTags.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allTags.length + 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final tag = isAll ? null : allTags[index - 1];
                      final isSelected =
                          isAll ? _selectedTags.isEmpty : _selectedTags.contains(tag);

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
                          selectedColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
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
                child: workouts.isEmpty
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
                            Text(
                              _isSearching || _selectedTags.isNotEmpty
                                  ? 'No workouts match your criteria'
                                  : 'No workouts found. Add some!',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: workouts.length,
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderWorkouts(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final workout = workouts[index];

                          return PremiumCard(
                            key: ValueKey(workout.id),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkoutDetailScreen(workoutId: workout.id),
                                ),
                              );
                            },
                            child: Slidable(
                              key: ValueKey(workout.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      _showEditWorkoutDialog(context, workout);
                                    },
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
                                        'Workout',
                                      );
                                      if (confirm == true) {
                                        provider.deleteWorkout(workout.id);
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
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.fitness_center,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workout.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            workout.allNotes.isNotEmpty
                                                ? workout.allNotes.first
                                                : 'No notes...',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (workout.tags != null &&
                                              workout.tags!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 2,
                                                children: workout.tags!
                                                    .take(3)
                                                    .map((tag) => Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          child: Text(
                                                            tag,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ))
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(
                                          alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Bench Press)',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Description (Optional)'),
              textCapitalization: TextCapitalization.sentences,
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
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<WorkoutProvider>(context, listen: false).addWorkout(
                  nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkoutDialog(BuildContext context, Workout workout) {
    final nameController = TextEditingController(text: workout.name);
    final descriptionController =
        TextEditingController(text: workout.description ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Bench Press)',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              textCapitalization: TextCapitalization.sentences,
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
              if (nameController.text.trim().isNotEmpty) {
                final provider = Provider.of<WorkoutProvider>(
                  context,
                  listen: false,
                );
                provider.updateWorkoutName(
                    workout.id, nameController.text.trim());
                provider.updateWorkoutDescription(
                    workout.id, descriptionController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
