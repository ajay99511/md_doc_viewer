import 'package:path/path.dart' as p;

/// Represents a single node in the file tree — either a file or a folder.
class FileNode {
  final String path;
  final String name;
  final bool isDirectory;
  final DateTime? lastModified;
  final int? size; // bytes, only for files
  final List<FileNode> children;
  bool isExpanded;

  FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.lastModified,
    this.size,
    List<FileNode>? children,
    this.isExpanded = false,
  }) : children = children ?? [];

  /// Get file extension without dot, lowercase.
  String get extension {
    if (isDirectory) return '';
    return p.extension(name).replaceAll('.', '').toLowerCase();
  }

  /// Check if this is a markdown file.
  bool get isMarkdown {
    if (isDirectory) return false;
    final ext = extension;
    return ext == 'md' || ext == 'markdown' || ext == 'mdx';
  }

  /// Check if this file should be shown based on settings.
  bool isSupportedFile(Set<String> allowedExtensions) {
    if (isDirectory) return true;
    return allowedExtensions.contains(extension);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileNode &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
