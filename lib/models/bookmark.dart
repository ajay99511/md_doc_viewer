/// Represents a bookmarked (starred) folder for quick access.
class Bookmark {
  final String id;
  final String path;
  final String label; // Custom display name
  final int order; // Sort order in bookmark list
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.path,
    required this.label,
    required this.order,
    required this.createdAt,
  });

  /// Create from JSON (for SharedPreferences persistence).
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      path: json['path'] as String,
      label: json['label'] as String? ?? json['path'] as String,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'label': label,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Bookmark copyWith({
    String? id,
    String? path,
    String? label,
    int? order,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      path: path ?? this.path,
      label: label ?? this.label,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
