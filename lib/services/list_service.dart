import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_list.dart';

/// Service for persisting and managing file lists (collections).
class ListService {
  static const _keyLists = 'file_lists';

  /// Load all lists.
  Future<List<FileList>> loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyLists);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => FileList.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all lists.
  Future<void> saveLists(List<FileList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = lists.map((l) => l.toJson()).toList();
    await prefs.setString(_keyLists, jsonEncode(jsonList));
  }

  /// Create a new list.
  Future<List<FileList>> createList({
    required String name,
    String? description,
    List<String>? folderPaths,
  }) async {
    final lists = await loadLists();
    final now = DateTime.now();

    final newList = FileList(
      id: 'list_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      folderPaths: folderPaths ?? [],
      createdAt: now,
      updatedAt: now,
    );

    final updated = [...lists, newList];
    await saveLists(updated);
    return updated;
  }

  /// Delete a list.
  Future<List<FileList>> deleteList(String listId) async {
    final lists = await loadLists();
    final updated = lists.where((l) => l.id != listId).toList();
    await saveLists(updated);
    return updated;
  }

  /// Update list name.
  Future<List<FileList>> updateName(String listId, String newName) async {
    final lists = await loadLists();
    final updated = lists.map((l) {
      if (l.id == listId) {
        return l.copyWith(name: newName, updatedAt: DateTime.now());
      }
      return l;
    }).toList();
    await saveLists(updated);
    return updated;
  }

  /// Add a folder to a list.
  Future<List<FileList>> addFolder(String listId, String folderPath) async {
    final lists = await loadLists();
    final updated = lists.map((l) {
      if (l.id == listId && !l.containsFolder(folderPath)) {
        return l.copyWith(
          folderPaths: [...l.folderPaths, folderPath],
          updatedAt: DateTime.now(),
        );
      }
      return l;
    }).toList();
    await saveLists(updated);
    return updated;
  }

  /// Remove a folder from a list.
  Future<List<FileList>> removeFolder(String listId, String folderPath) async {
    final lists = await loadLists();
    final updated = lists.map((l) {
      if (l.id == listId) {
        return l.copyWith(
          folderPaths: l.folderPaths.where((p) => p != folderPath).toList(),
          updatedAt: DateTime.now(),
        );
      }
      return l;
    }).toList();
    await saveLists(updated);
    return updated;
  }

  /// Check if a folder is in a specific list.
  Future<bool> isFolderInList(String listId, String folderPath) async {
    final lists = await loadLists();
    final list = lists.firstWhere((l) => l.id == listId, orElse: () => FileList(
      id: '', name: '', folderPaths: [], createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));
    return list.containsFolder(folderPath);
  }

  /// Get all lists that contain a specific folder.
  Future<List<FileList>> getListsContainingFolder(String folderPath) async {
    final lists = await loadLists();
    return lists.where((l) => l.containsFolder(folderPath)).toList();
  }
}
