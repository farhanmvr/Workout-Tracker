import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backup_service.dart';
import '../services/google_drive_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isSigningIn = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isSignedIn = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    final signedIn = await _driveService.isSignedIn;
    setState(() {
      _isSignedIn = signedIn;
    });
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await _driveService.signIn();
      if (account != null) {
        setState(() {
          _isSignedIn = true;
          _userName = account.displayName;
        });
      }
    } on Exception catch (e) {
      String message = 'Sign in failed: $e';
      
      // Handle PlatformException specifically if possible
      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('error 10')) {
          message = 'Developer Error (10): This usually means your SHA-1 fingerprint or package name does not match the Google Cloud Console configuration.';
        } else if (e.toString().contains('error 12500')) {
          message = 'Sign-in Failed (12500): Often caused by an incorrect configuration in the Google Cloud Console or a missing google-services.json file.';
        } else if (e.toString().contains('invalid_client')) {
          message = 'Invalid Client: The client ID used in your app does not match the one in the Google Cloud Console.';
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign-In Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => _showTroubleshootingDialog(),
              child: const Text('TROUBLESHOOT'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isSigningIn = false);
    }
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting Google Drive'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To enable Google Drive sync, ensure:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('1. SHA-1 Fingerprint: Add your debug and release SHA-1 certificates to your project in the Google Cloud Console or Firebase.'),
              SizedBox(height: 8),
              Text('2. Package Name: Ensure "com.farhanmvr.workout_track" matches exactly in the console.'),
              SizedBox(height: 8),
              Text('3. Drive API: Enable the "Google Drive API" in your Google Cloud project.'),
              SizedBox(height: 8),
              Text('4. Services File: Download "google-services.json" (Android) or "GoogleService-Info.plist" (iOS) and place them in the correct app directories.'),
              SizedBox(height: 8),
              Text('5. Consent Screen: Configure the OAuth consent screen and add yourself as a test user if the app is not published.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await _driveService.signOut();
    setState(() {
      _isSignedIn = false;
      _userName = null;
    });
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final zipFile = await BackupService.createBackupZip();
      await _driveService.uploadBackup(zipFile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will overwrite all current data with the backup from the cloud. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final zipFile = await _driveService.downloadBackup();
      if (zipFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup found on Drive.')),
        );
        return;
      }

      await BackupService.restoreFromZip(zipFile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore successful! Please restart the app.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryCyan = Color(0xFF22D3EE);
    const slate800 = Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Sync'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Cloud Storage'),
            const SizedBox(height: 16),
            _buildCloudCard(
              title: 'Google Drive',
              subtitle: _isSignedIn 
                  ? 'Connected as ${_userName ?? "User"}' 
                  : 'Sign in to sync your data',
              icon: Icons.cloud_queue_rounded,
              isConnected: _isSignedIn,
              onAction: _isSignedIn ? _handleSignOut : _handleSignIn,
              isLoading: _isSigningIn,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Operations'),
            const SizedBox(height: 16),
            _buildOperationButton(
              title: 'Backup to Cloud',
              subtitle: 'Zip and upload your current data',
              icon: Icons.upload_rounded,
              color: primaryCyan,
              onPressed: _isSignedIn ? _handleBackup : null,
              isLoading: _isBackingUp,
            ),
            const SizedBox(height: 16),
            _buildOperationButton(
              title: 'Restore from Cloud',
              subtitle: 'Download and replace local data',
              icon: Icons.download_rounded,
              color: Colors.orangeAccent,
              onPressed: _isSignedIn ? _handleRestore : null,
              isLoading: _isRestoring,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slate800,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Backups include all workouts, sessions, weight history, and user profiles.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildCloudCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isConnected,
    required VoidCallback onAction,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? const Color(0xFF22D3EE).withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF22D3EE).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isConnected ? const Color(0xFF22D3EE) : Colors.white38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton(
              onPressed: onAction,
              child: Text(isConnected ? 'DISCONNECT' : 'CONNECT'),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
