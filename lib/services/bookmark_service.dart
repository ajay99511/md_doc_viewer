import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

/// Service for persisting and retrieving bookmarks.
class BookmarkService {
  static const _keyBookmarks = 'bookmarks';

  /// Load all bookmarks from SharedPreferences.
  Future<List<Bookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBookmarks);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      return [];
    }
  }

  /// Save all bookmarks to SharedPreferences.
  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await prefs.setString(_keyBookmarks, jsonEncode(jsonList));
  }

  /// Add a new bookmark.
  Future<List<Bookmark>> addBookmark({
    required String path,
    String? label,
  }) async {
    final bookmarks = await loadBookmarks();

    // Don't add duplicates
    if (bookmarks.any((b) => b.path == path)) return bookmarks;

    final maxOrder = bookmarks.isEmpty ? 0 : bookmarks.map((b) => b.order).reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    final newBookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      label: label ?? path,
      order: maxOrder + 1,
      createdAt: now,
    );

    final updated = [...bookmarks, newBookmark];
    await saveBookmarks(updated);
    return updated;
  }

  /// Remove a bookmark by path.
  Future<List<Bookmark>> removeBookmark(String path) async {
    final bookmarks = await loadBookmarks();
    final updated = bookmarks.where((b) => b.path != path).toList();
    await saveBookmarks(updated);
    return updated;
  }

  /// Check if a path is bookmarked.
  Future<bool> isBookmarked(String path) async {
    final bookmarks = await loadBookmarks();
    return bookmarks.any((b) => b.path == path);
  }

  /// Update bookmark label.
  Future<List<Bookmark>> updateLabel(String path, String newLabel) async {
    final bookmarks = await loadBookmarks();
    final updated = bookmarks.map((b) {
      if (b.path == path) return b.copyWith(label: newLabel);
      return b;
    }).toList();
    await saveBookmarks(updated);
    return updated;
  }

  /// Reorder bookmarks (move item from [oldIndex] to [newIndex]).
  Future<List<Bookmark>> reorder(int oldIndex, int newIndex) async {
    final bookmarks = await loadBookmarks();
    if (oldIndex < 0 || oldIndex >= bookmarks.length) return bookmarks;
    if (newIndex < 0 || newIndex >= bookmarks.length) return bookmarks;

    final item = bookmarks.removeAt(oldIndex);
    bookmarks.insert(newIndex, item);

    // Reassign order
    final reordered = bookmarks.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();

    await saveBookmarks(reordered);
    return reordered;
  }
}
