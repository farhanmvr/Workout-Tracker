import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  /// Zips all .hive and .lock files in the application documents directory.
  /// Returns the File object of the resulting zip.
  static Future<File> createBackupZip() async {
    final directory = await getApplicationDocumentsDirectory();
    final zipFile = File(p.join((await getTemporaryDirectory()).path, 'workout_backup.zip'));

    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);

    final files = directory.listSync(recursive: false);
    for (var file in files) {
      if (file is File) {
        final filename = p.basename(file.path);
        // Only backup Hive box files and lock files
        if (filename.endsWith('.hive') || filename.endsWith('.lock')) {
          encoder.addFile(file);
        }
      }
    }

    encoder.close();
    return zipFile;
  }

  /// Extracts the given zip file into the application documents directory.
  /// Warning: This will overwrite existing Hive boxes.
  static Future<void> restoreFromZip(File zipFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final targetFile = File(p.join(directory.path, filename));
        await targetFile.writeAsBytes(data, flush: true);
      }
    }
  }

  /// Shares the backup zip file using the system share sheet.
  static Future<void> exportBackup(dynamic context) async {
    final zipFile = await createBackupZip();
    final xFile = XFile(zipFile.path, mimeType: 'application/zip');
    await Share.shareXFiles([xFile], text: 'Workout Tracker Backup');
  }

  /// Picks a zip file and restores it.
  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await restoreFromZip(file);
      return true;
    }
    return false;
  }
}
