import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/session.dart';
import '../utils/dialogs.dart';
import 'session_detail_screen.dart';
import 'profiles_screen.dart';
import '../widgets/premium_card.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bar_action_button.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearching = false;

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
                  hintText: 'Search sessions...',
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
            : const Text('Sessions'),
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
            onPressed: () => _showAddSessionDialog(context),
            icon: Icons.add,
            tooltip: 'New Session',
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
          final sessions = provider.sessions.where((s) {
            return s.name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'No sessions match "$_searchQuery"'
                        : 'No sessions recorded yet!',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: sessions.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderSessions(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final session = sessions[index];
              final initials =
                  session.name.isNotEmpty ? session.name[0].toUpperCase() : '?';

              return PremiumCard(
                key: ValueKey(session.id),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionDetailScreen(sessionId: session.id),
                    ),
                  );
                },
                child: Slidable(
                  key: ValueKey(session.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.5,
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          _showEditSessionNameDialog(context, session);
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Edit',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirm = await showDeleteConfirmation(
                            context,
                            'Session',
                          );
                          if (confirm == true) {
                            provider.deleteSession(session.id);
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
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.exercises.length} Workouts',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Session'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Routine (e.g. Push, Pull, Legs)',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Provider.of<WorkoutProvider>(
                    context,
                    listen: false,
                  ).addSession(nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('START'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSessionNameDialog(
    BuildContext context,
    WorkoutSession session,
  ) {
    final nameController = TextEditingController(text: session.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Session Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Routine (e.g. Push, Pull, Legs)',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Provider.of<WorkoutProvider>(
                    context,
                    listen: false,
                  ).updateSessionName(session.id, nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
