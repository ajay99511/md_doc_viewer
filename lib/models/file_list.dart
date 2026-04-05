/// A user-defined collection of folder paths.
/// Like a "playlist" for folders — group related folders together.
class FileList {
  final String id;
  final String name;
  final String? description;
  final List<String> folderPaths; // Ordered list of folder paths
  final DateTime createdAt;
  final DateTime updatedAt;

  FileList({
    required this.id,
    required this.name,
    this.description,
    required this.folderPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileList.fromJson(Map<String, dynamic> json) {
    return FileList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      folderPaths: List<String>.from(json['folderPaths'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'folderPaths': folderPaths,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FileList copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? folderPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      folderPaths: folderPaths ?? this.folderPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool containsFolder(String path) => folderPaths.contains(path);
}
