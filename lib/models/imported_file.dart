import 'dart:convert';

/// Represents a markdown file that was imported into the app's local library.
///
/// Files are copied into the app's internal documents directory so they
/// persist regardless of original source availability or permission state.
class ImportedFile {
  /// Unique identifier (millisecondsSinceEpoch at import time).
  final String id;

  /// Original file name as shown to the user (e.g., `README.md`).
  final String originalName;

  /// Absolute path to the copied file inside the app documents directory.
  final String storedPath;

  /// When the file was imported.
  final DateTime importedAt;

  /// File size in bytes.
  final int fileSize;

  const ImportedFile({
    required this.id,
    required this.originalName,
    required this.storedPath,
    required this.importedAt,
    required this.fileSize,
  });

  /// Create from a JSON map (loaded from SharedPreferences).
  factory ImportedFile.fromJson(Map<String, dynamic> json) {
    return ImportedFile(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      storedPath: json['storedPath'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      fileSize: json['fileSize'] as int,
    );
  }

  /// Serialize to a JSON map (for SharedPreferences storage).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalName': originalName,
      'storedPath': storedPath,
      'importedAt': importedAt.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  /// Decode a JSON string list into a list of ImportedFile.
  static List<ImportedFile> decodeList(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => ImportedFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Encode a list of ImportedFile into a JSON string.
  static String encodeList(List<ImportedFile> files) {
    return jsonEncode(files.map((f) => f.toJson()).toList());
  }

  /// Human-readable file size.
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportedFile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
