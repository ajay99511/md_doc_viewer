import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bookmark_service.dart';

/// Simplified bookmark data for the UI.
class BookmarkData {
  final String path;
  final String label;
  final int order;

  BookmarkData({required this.path, required this.label, required this.order});
}

/// All bookmarks state.
final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, AsyncValue<List<BookmarkData>>>((ref) {
  return BookmarksNotifier(BookmarkService());
});

class BookmarksNotifier extends StateNotifier<AsyncValue<List<BookmarkData>>> {
  final BookmarkService _service;

  BookmarksNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final bookmarks = await _service.loadBookmarks();
      state = AsyncValue.data(bookmarks
          .map((b) => BookmarkData(path: b.path, label: b.label, order: b.order))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String path, [String? label]) async {
    try {
      final updated = await _service.addBookmark(path: path, label: label);
      state = AsyncValue.data(updated
          .map((b) => BookmarkData(path: b.path, label: b.label, order: b.order))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove(String path) async {
    try {
      final updated = await _service.removeBookmark(path);
      state = AsyncValue.data(updated
          .map((b) => BookmarkData(path: b.path, label: b.label, order: b.order))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    try {
      final updated = await _service.reorder(oldIndex, newIndex);
      state = AsyncValue.data(updated
          .map((b) => BookmarkData(path: b.path, label: b.label, order: b.order))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isBookmarked(String path) {
    return state.value?.any((b) => b.path == path) ?? false;
  }
}
