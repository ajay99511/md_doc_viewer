import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_list.dart';
import '../services/list_service.dart';

/// Simplified list data for the UI.
class ListData {
  final String id;
  final String name;
  final String? description;
  final int folderCount;

  ListData({
    required this.id,
    required this.name,
    this.description,
    required this.folderCount,
  });
}

/// All file lists state.
final listsProvider = StateNotifierProvider<ListsNotifier, AsyncValue<List<ListData>>>((ref) {
  return ListsNotifier();
});

class ListsNotifier extends StateNotifier<AsyncValue<List<ListData>>> {
  final ListService _service = ListService();

  ListsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await _service.loadLists();
      state = AsyncValue.data(lists
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({required String name, String? description}) async {
    try {
      final updated = await _service.createList(name: name, description: description);
      state = AsyncValue.data(updated
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String listId) async {
    try {
      final updated = await _service.deleteList(listId);
      state = AsyncValue.data(updated
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rename(String listId, String newName) async {
    try {
      final updated = await _service.updateName(listId, newName);
      state = AsyncValue.data(updated
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFolder(String listId, String folderPath) async {
    try {
      final updated = await _service.addFolder(listId, folderPath);
      state = AsyncValue.data(updated
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFolder(String listId, String folderPath) async {
    try {
      final updated = await _service.removeFolder(listId, folderPath);
      state = AsyncValue.data(updated
          .map((l) => ListData(
                id: l.id,
                name: l.name,
                description: l.description,
                folderCount: l.folderPaths.length,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get full list details by ID.
  Future<FileList?> getListById(String listId) async {
    final lists = await _service.loadLists();
    try {
      return lists.firstWhere((l) => l.id == listId);
    } catch (e) {
      return null;
    }
  }
}
