import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/imported_file.dart';
import '../providers/imported_files_provider.dart';
import '../utils/constants.dart';
import 'md_reader_screen.dart';

/// Mobile-native Markdown Library screen with full CRUD operations.
///
/// Features:
/// - Import .md files from device storage (file_picker)
/// - Persisted file list with search & sort
/// - Swipe-to-delete with confirmation
/// - Multi-select mode for bulk deletion
/// - Tap to open in full-screen reader
/// - Beautiful empty state
class MdLibraryScreen extends ConsumerStatefulWidget {
  const MdLibraryScreen({super.key});

  @override
  ConsumerState<MdLibraryScreen> createState() => _MdLibraryScreenState();
}

class _MdLibraryScreenState extends ConsumerState<MdLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importFiles() async {
    final notifier = ref.read(importedFilesProvider.notifier);
    final count = await notifier.importFiles();
    if (mounted && count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $count file${count > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(ImportedFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete File',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${file.originalName}" from your library?\n\nThis will delete the stored copy.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(importedFilesProvider.notifier).deleteFile(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${file.originalName} deleted',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.backgroundElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final state = ref.read(importedFilesProvider);
    final count = state.selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Selected',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove $count file${count > 1 ? 's' : ''} from your library?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(importedFilesProvider.notifier).deleteSelected();
    }
  }

  void _showSortMenu() {
    final currentSort = ref.read(importedFilesProvider).sortMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ..._buildSortOptions(ctx, currentSort),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSortOptions(BuildContext ctx, LibrarySortMode current) {
    final options = [
      (LibrarySortMode.dateNewest, 'Newest First', PhosphorIconsRegular.clockCounterClockwise),
      (LibrarySortMode.dateOldest, 'Oldest First', PhosphorIconsRegular.clock),
      (LibrarySortMode.name, 'Name (A–Z)', PhosphorIconsRegular.sortAscending),
      (LibrarySortMode.sizeLargest, 'Largest First', PhosphorIconsRegular.arrowUp),
      (LibrarySortMode.sizeSmallest, 'Smallest First', PhosphorIconsRegular.arrowDown),
    ];

    return options.map((opt) {
      final isActive = current == opt.$1;
      return ListTile(
        leading: PhosphorIcon(
          opt.$3,
          size: 22,
          color: isActive ? AppColors.accent : AppColors.textMuted,
        ),
        title: Text(
          opt.$2,
          style: TextStyle(
            color: isActive ? AppColors.accent : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isActive
            ? PhosphorIcon(PhosphorIconsFill.checkCircle, size: 20, color: AppColors.accent)
            : null,
        onTap: () {
          ref.read(importedFilesProvider.notifier).setSortMode(opt.$1);
          Navigator.pop(ctx);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importedFilesProvider);
    final isMultiSelect = state.isMultiSelectMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: _buildAppBar(state, isMultiSelect),
      body: Column(
        children: [
          // Search bar (animated slide-in)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _showSearch ? _buildSearchBar() : const SizedBox.shrink(),
          ),
          // File count & sort row
          if (state.files.isNotEmpty) _buildInfoBar(state),
          // Main content
          Expanded(child: _buildContent(state)),
        ],
      ),
      floatingActionButton: !isMultiSelect
          ? ScaleTransition(
              scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
              child: FloatingActionButton.extended(
                heroTag: 'importMdFiles',
                onPressed: _importFiles,
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                icon: PhosphorIcon(PhosphorIconsRegular.plus, size: 22),
                label: const Text(
                  'Import',
                  style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ImportedFilesState state, bool isMultiSelect) {
    if (isMultiSelect) {
      return AppBar(
        backgroundColor: AppColors.backgroundElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => ref.read(importedFilesProvider.notifier).clearSelection(),
        ),
        title: Text(
          '${state.selectedIds.length} selected',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(importedFilesProvider.notifier).selectAll(),
            child: const Text('All', style: TextStyle(color: AppColors.accent)),
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIconsRegular.trash, size: 22, color: AppColors.error),
            onPressed: _confirmDeleteSelected,
            tooltip: 'Delete selected',
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.backgroundSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.books,
            size: 22,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          const Text(
            'My Library',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (state.files.isNotEmpty) ...[
          IconButton(
            icon: PhosphorIcon(
              _showSearch ? PhosphorIconsFill.magnifyingGlass : PhosphorIconsRegular.magnifyingGlass,
              size: 22,
              color: _showSearch ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(importedFilesProvider.notifier).setSearchQuery('');
                }
              });
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.funnel,
              size: 22,
              color: AppColors.textSecondary,
            ),
            onPressed: _showSortMenu,
            tooltip: 'Sort',
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (value) =>
                  ref.read(importedFilesProvider.notifier).setSearchQuery(value),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: PhosphorIcon(PhosphorIconsRegular.x, size: 16, color: AppColors.textMuted),
              onPressed: () {
                _searchController.clear();
                ref.read(importedFilesProvider.notifier).setSearchQuery('');
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInfoBar(ImportedFilesState state) {
    final filtered = state.filteredFiles;
    final total = state.files.length;
    final showing = filtered.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            showing == total ? '$total files' : '$showing of $total files',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            _sortModeLabel(state.sortMode),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _sortModeLabel(LibrarySortMode mode) {
    return switch (mode) {
      LibrarySortMode.name => 'A–Z',
      LibrarySortMode.dateNewest => 'Newest',
      LibrarySortMode.dateOldest => 'Oldest',
      LibrarySortMode.sizeSmallest => 'Smallest',
      LibrarySortMode.sizeLargest => 'Largest',
    };
  }

  Widget _buildContent(ImportedFilesState state) {
    if (state.isLoading && state.files.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      );
    }

    if (state.error != null && state.files.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.files.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = state.filteredFiles;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No files match "${state.searchQuery}"',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(importedFilesProvider.notifier).loadAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.backgroundElevated,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // bottom padding for FAB
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final file = filtered[index];
          return _FileCard(
            file: file,
            isSelected: state.selectedIds.contains(file.id),
            isMultiSelectMode: state.isMultiSelectMode,
            onTap: () {
              if (state.isMultiSelectMode) {
                ref.read(importedFilesProvider.notifier).toggleSelection(file.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MdReaderScreen(file: file)),
                );
              }
            },
            onLongPress: () {
              ref.read(importedFilesProvider.notifier).toggleSelection(file.id);
            },
            onDelete: () => _confirmDelete(file),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: PhosphorIcon(
                PhosphorIconsRegular.books,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Your Library is Empty',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Import Markdown files from your device\nto build your personal reading library.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Feature hints
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _FeatureHint(
                    icon: PhosphorIconsRegular.fileArrowUp,
                    text: 'Import .md files from storage',
                  ),
                  const SizedBox(height: 12),
                  _FeatureHint(
                    icon: PhosphorIconsRegular.bookOpen,
                    text: 'Read with beautiful rendering',
                  ),
                  const SizedBox(height: 12),
                  _FeatureHint(
                    icon: PhosphorIconsRegular.shieldCheck,
                    text: 'Files persist across sessions',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _importFiles,
              icon: PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
              label: const Text(
                'Import Files',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              error,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref.read(importedFilesProvider.notifier).loadAll(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single file card in the library list.
class _FileCard extends StatelessWidget {
  final ImportedFile file;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _FileCard({
    required this.file,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(file.id),
        direction: isMultiSelectMode
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: PhosphorIcon(
            PhosphorIconsRegular.trash,
            size: 24,
            color: AppColors.error,
          ),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false; // We handle deletion via the confirm dialog
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accent.withValues(alpha: 0.4) : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Selection checkbox or file icon
                    if (isMultiSelectMode)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          key: ValueKey(isSelected),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.borderDefault,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      )
                    else
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsRegular.fileText,
                          size: 22,
                          color: AppColors.accent,
                        ),
                      ),
                    const SizedBox(width: 14),
                    // File info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.originalName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                file.formattedSize,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                _formatDate(file.importedAt),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Trailing action
                    if (!isMultiSelectMode)
                      PhosphorIcon(
                        PhosphorIconsRegular.caretRight,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Small hint row used in the empty state.
class _FeatureHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
