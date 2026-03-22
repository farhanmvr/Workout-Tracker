import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/stats_provider.dart';
import '../services/backup_service.dart';
import '../widgets/premium_card.dart';
import '../services/export_service.dart';
import 'profiles_screen.dart';
import '../providers/profile_provider.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isProcessing = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    try {
      await BackupService.exportBackup(context);
      _showSnackBar('Backup exported successfully');
    } catch (e) {
      _showSnackBar('Backup failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleBulkExport() async {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    if (workoutProvider.sessions.isEmpty) {
      _showSnackBar('No sessions to export', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final workoutMap = {for (var w in workoutProvider.workouts) w.id: w};
      await ExportService.exportAllSessionsToPdf(
          context, workoutProvider.sessions, workoutMap);
      _showSnackBar('All sessions exported successfully');
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImport() async {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
          'This will OVERWRITE all your current data with the data from the backup file. This action cannot be undone.',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('IMPORT & OVERWRITE',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await BackupService.importBackup();
      if (!mounted) return;
      if (success) {
        // Refresh providers using pre-captured references
        await workoutProvider.init();
        await statsProvider.init();
        _showSnackBar('Data restored successfully');
      }
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilesScreen()),
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
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              PremiumCard(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text('Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.dark
                        ? 'Enabled'
                        : 'Disabled',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  activeTrackColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Data Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              PremiumCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sync_rounded, color: Color(0xFF22D3EE)),
                      title: const Text('Cloud Backup & Sync',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Sync data to Google Drive or iCloud',
                          style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BackupScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined,
                          color: Colors.redAccent),
                      title: const Text('Export All Sessions PDF',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text(
                          'Generate a single PDF with all your session data',
                          style: TextStyle(fontSize: 12)),
                      onTap: _isProcessing ? null : _handleBulkExport,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.cloud_upload_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Backup Data (JSON)',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Export and share your full database',
                          style: TextStyle(fontSize: 12)),
                      onTap: _isProcessing ? null : _handleExport,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.cloud_download_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Restore Data',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Import data from a backup file',
                          style: TextStyle(fontSize: 12)),
                      onTap: _isProcessing ? null : _handleImport,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Backup includes all your workouts, sessions, history, and stats. It is stored in a JSON format.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
