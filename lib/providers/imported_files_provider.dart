import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/imported_file.dart';
import '../services/import_service.dart';

/// Singleton provider for the import service.
final importServiceProvider = Provider<ImportService>((ref) => ImportService());

/// Sort options for the library file list.
enum LibrarySortMode { name, dateNewest, dateOldest, sizeSmallest, sizeLargest }

/// State for the imported files library.
class ImportedFilesState {
  final List<ImportedFile> files;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final LibrarySortMode sortMode;
  final Set<String> selectedIds; // for multi-select mode

  const ImportedFilesState({
    this.files = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sortMode = LibrarySortMode.dateNewest,
    this.selectedIds = const {},
  });

  ImportedFilesState copyWith({
    List<ImportedFile>? files,
    bool? isLoading,
    String? error,
    String? searchQuery,
    LibrarySortMode? sortMode,
    Set<String>? selectedIds,
  }) {
    return ImportedFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Files filtered by search query and sorted by current sort mode.
  List<ImportedFile> get filteredFiles {
    var result = files.toList();

    // Filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((f) => f.originalName.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (sortMode) {
      case LibrarySortMode.name:
        result.sort((a, b) => a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()));
      case LibrarySortMode.dateNewest:
        result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      case LibrarySortMode.dateOldest:
        result.sort((a, b) => a.importedAt.compareTo(b.importedAt));
      case LibrarySortMode.sizeSmallest:
        result.sort((a, b) => a.fileSize.compareTo(b.fileSize));
      case LibrarySortMode.sizeLargest:
        result.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    }

    return result;
  }

  bool get isMultiSelectMode => selectedIds.isNotEmpty;
}

/// Provider for the imported files library with full CRUD operations.
final importedFilesProvider =
    StateNotifierProvider<ImportedFilesNotifier, ImportedFilesState>((ref) {
  return ImportedFilesNotifier(ref.read(importServiceProvider));
});

class ImportedFilesNotifier extends StateNotifier<ImportedFilesState> {
  final ImportService _service;

  ImportedFilesNotifier(this._service) : super(const ImportedFilesState()) {
    loadAll();
  }

  /// Load all imported files from persistence.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final files = await _service.loadImportedFiles();
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load library: $e');
    }
  }

  /// Open file picker and import selected .md files.
  Future<int> importFiles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newFiles = await _service.pickAndImportFiles();
      if (newFiles.isNotEmpty) {
        final updatedFiles = [...state.files, ...newFiles];
        state = state.copyWith(files: updatedFiles, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return newFiles.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to import: $e');
      return 0;
    }
  }

  /// Delete a single file.
  Future<void> deleteFile(ImportedFile file) async {
    await _service.deleteFile(file);
    final updated = state.files.where((f) => f.id != file.id).toList();
    final updatedSelected = Set<String>.from(state.selectedIds)..remove(file.id);
    state = state.copyWith(files: updated, selectedIds: updatedSelected);
  }

  /// Delete all currently selected files.
  Future<void> deleteSelected() async {
    final toDelete = state.files.where((f) => state.selectedIds.contains(f.id)).toList();
    if (toDelete.isEmpty) return;

    await _service.deleteFiles(toDelete);
    final remaining = state.files.where((f) => !state.selectedIds.contains(f.id)).toList();
    state = state.copyWith(files: remaining, selectedIds: {});
  }

  /// Toggle selection of a file (for multi-select mode).
  void toggleSelection(String id) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(selectedIds: updated);
  }

  /// Select all files.
  void selectAll() {
    state = state.copyWith(selectedIds: state.files.map((f) => f.id).toSet());
  }

  /// Clear all selections.
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Set search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set sort mode.
  void setSortMode(LibrarySortMode mode) {
    state = state.copyWith(sortMode: mode);
  }
}
