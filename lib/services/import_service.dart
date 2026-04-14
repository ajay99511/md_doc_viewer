import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/imported_file.dart';

/// Service handling import, persistence, and lifecycle of user-imported markdown files.
///
/// Files are **copied** into the app's internal documents directory
/// (`getApplicationDocumentsDirectory()/md_library/`) to survive permission
/// revocations and source file deletions — critical for Android Scoped Storage.
class ImportService {
  static const _prefsKey = 'md_library_imported_files';
  static const _libraryDirName = 'md_library';

  // ─── Public API ───

  /// Open the system file picker filtered to `.md` files, copy selected files
  /// into app storage, and return the list of newly imported [ImportedFile]s.
  ///
  /// Returns an empty list if the user cancels or no valid files are picked.
  Future<List<ImportedFile>> pickAndImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'mdx', 'txt'],
      allowMultiple: true,
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return [];

    final importedFiles = <ImportedFile>[];
    final libDir = await _ensureLibraryDir();
    final existing = await loadImportedFiles();
    final existingNames = existing.map((f) => f.originalName).toSet();

    for (final platformFile in result.files) {
      if (platformFile.path == null) continue;

      try {
        final sourceFile = File(platformFile.path!);
        if (!await sourceFile.exists()) continue;

        final originalName = platformFile.name;
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Deduplicate names: if "README.md" already exists, use "README_1681234567890.md"
        String storedName = originalName;
        if (existingNames.contains(originalName)) {
          final baseName = p.basenameWithoutExtension(originalName);
          final ext = p.extension(originalName);
          storedName = '${baseName}_$timestamp$ext';
        }

        final destPath = p.join(libDir.path, storedName);
        await sourceFile.copy(destPath);

        final stat = await File(destPath).stat();

        final imported = ImportedFile(
          id: '$timestamp',
          originalName: originalName,
          storedPath: destPath,
          importedAt: DateTime.now(),
          fileSize: stat.size,
        );

        importedFiles.add(imported);
        existingNames.add(originalName);
      } catch (e) {
        // Skip files that fail to import — don't crash the whole batch
        continue;
      }
    }

    if (importedFiles.isNotEmpty) {
      final allFiles = [...existing, ...importedFiles];
      await _saveImportedFiles(allFiles);
    }

    return importedFiles;
  }

  /// Delete an imported file from both disk and the persisted list.
  Future<void> deleteFile(ImportedFile file) async {
    // Remove from disk
    try {
      final f = File(file.storedPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // Best-effort — if we can't delete, at least remove from list
    }

    // Remove from persisted list
    final files = await loadImportedFiles();
    files.removeWhere((f) => f.id == file.id);
    await _saveImportedFiles(files);
  }

  /// Delete multiple imported files at once.
  Future<void> deleteFiles(List<ImportedFile> filesToDelete) async {
    final idsToDelete = filesToDelete.map((f) => f.id).toSet();

    // Remove from disk
    for (final file in filesToDelete) {
      try {
        final f = File(file.storedPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {
        continue;
      }
    }

    // Remove from persisted list
    final files = await loadImportedFiles();
    files.removeWhere((f) => idsToDelete.contains(f.id));
    await _saveImportedFiles(files);
  }

  /// Read the content of a stored imported file.
  Future<String?> readFileContent(String storedPath) async {
    try {
      final file = File(storedPath);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  /// Load the persisted list of imported files from SharedPreferences.
  Future<List<ImportedFile>> loadImportedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      return ImportedFile.decodeList(jsonStr);
    } catch (e) {
      return [];
    }
  }

  // ─── Private ───

  /// Persist the full list of imported files to SharedPreferences.
  Future<void> _saveImportedFiles(List<ImportedFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, ImportedFile.encodeList(files));
  }

  /// Ensure the `md_library` subdirectory exists inside app documents.
  Future<Directory> _ensureLibraryDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final libDir = Directory(p.join(appDir.path, _libraryDirName));
    if (!await libDir.exists()) {
      await libDir.create(recursive: true);
    }
    return libDir;
  }
}
