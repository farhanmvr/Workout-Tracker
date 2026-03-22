import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> get isSignedIn async => await _googleSignIn.isSignedIn();

  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    final Map<String, String> authHeaders = await account.authHeaders;
    final authenticateClient = _GoogleAuthClient(authHeaders);

    return drive.DriveApi(authenticateClient);
  }

  /// Uploads the backup file to Google Drive (appDataFolder).
  Future<void> uploadBackup(File file) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Drive API not initialized');

    // Check if file already exists to update it instead of creating a new one
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '${p.basename(file.path)}'",
    );

    final driveFile = drive.File();
    driveFile.name = p.basename(file.path);
    driveFile.parents = ['appDataFolder'];

    final media = drive.Media(file.openRead(), await file.length());

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // Update existing
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
    } else {
      // Create new
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Downloads the backup file from Google Drive.
  Future<File?> downloadBackup() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'workout_backup.zip'",
    );

    if (fileList.files == null || fileList.files!.isEmpty) return null;

    final fileId = fileList.files!.first.id!;
    // Get full media data
    final mediaData = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    
    final tempDir = await Directory.systemTemp.createTemp();
    final file = File(p.join(tempDir.path, 'workout_backup_downloaded.zip'));
    
    final List<int> dataBytes = [];
    await for (final data in mediaData.stream) {
      dataBytes.addAll(data);
    }
    await file.writeAsBytes(dataBytes);

    return file;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
