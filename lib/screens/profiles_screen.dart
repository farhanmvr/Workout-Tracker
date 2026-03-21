import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/premium_card.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_action_button.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profiles = profileProvider.profiles;
        final activeId = profileProvider.activeProfileId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Profiles'),
            centerTitle: true,
            actions: [
              AppBarActionButton(
                onPressed: () => _showAddProfileDialog(context, profileProvider),
                icon: Icons.add,
                tooltip: 'Add Profile',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isActive = profile.id == activeId;

              return PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                onTap: () {
                  profileProvider.setActiveProfile(profile.id);
                  Navigator.pop(context);
                },
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary
                              ]
                            : [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    profile.name,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    isActive ? 'Active Profile' : 'Tap to switch',
                    style: TextStyle(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_copy_outlined),
                        onPressed: () => _showCloneProfileDialog(
                            context, profileProvider, profile),
                        tooltip: 'Clone Profile',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditProfileDialog(
                            context, profileProvider, profile),
                      ),
                      if (profiles.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDeleteConfirmation(context,
                                'Profile and all its data? (Action cannot be undone)');
                            if (confirm == true) {
                              profileProvider.deleteProfile(profile.id);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context, ProfileProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name (e.g., John Doe)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addProfile(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showCloneProfileDialog(
      BuildContext context, ProfileProvider provider, dynamic profile) {
    final controller = TextEditingController(text: '${profile.name} (Copy)');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clone Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Enter a name for the new profile copied from "${profile.name}":',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'New Profile Name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.cloneProfile(profile.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('CLONE'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, ProfileProvider provider, dynamic profile) {
    final controller = TextEditingController(text: profile.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateProfile(profile.id, controller.text.trim());
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
