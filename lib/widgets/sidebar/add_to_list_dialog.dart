import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/file_list.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/palette.dart';

/// Dialog that lets the user add/remove a folder to/from their lists.
///
/// This is the populate flow for the Lists feature: it shows every existing
/// list with a checkbox reflecting whether [folderPath] belongs to it, and
/// offers an inline "Create new list" action that immediately includes the
/// folder.
class AddToListDialog extends ConsumerStatefulWidget {
  final String folderPath;
  final String folderName;

  const AddToListDialog({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  ConsumerState<AddToListDialog> createState() => _AddToListDialogState();
}

class _AddToListDialogState extends ConsumerState<AddToListDialog> {
  List<FileList> _lists = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final lists = await ref.read(listServiceProvider).loadLists();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  Future<void> _toggle(FileList list, bool shouldContain) async {
    if (_busy) return;
    setState(() => _busy = true);
    final notifier = ref.read(listsProvider.notifier);
    if (shouldContain) {
      await notifier.addFolder(list.id, widget.folderPath);
    } else {
      await notifier.removeFolder(list.id, widget.folderPath);
    }
    await _reload();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _createAndAdd() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _QuickNameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() => _busy = true);
    // Create the list including this folder in one step.
    await ref
        .read(listServiceProvider)
        .createList(name: name.trim(), folderPaths: [widget.folderPath]);
    // Refresh the provider so the sidebar reflects the new list.
    await ref.read(listsProvider.notifier).reload();
    await _reload();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.palette.backgroundElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.listPlus, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add to List',
              style: TextStyle(color: context.palette.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folderName,
                    style: TextStyle(color: context.palette.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (_lists.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No lists yet. Create one to group folders together.',
                        style: TextStyle(color: context.palette.textMuted, fontSize: 13),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: _lists.map((list) {
                          final contains = list.containsFolder(widget.folderPath);
                          return CheckboxListTile(
                            value: contains,
                            onChanged: _busy ? null : (v) => _toggle(list, v ?? false),
                            activeColor: AppColors.accent,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              list.name,
                              style: TextStyle(color: context.palette.textPrimary, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${list.folderPaths.length} folder${list.folderPaths.length == 1 ? '' : 's'}',
                              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _busy ? null : _createAndAdd,
                    icon: PhosphorIcon(PhosphorIconsRegular.plus, size: 16, color: AppColors.accent),
                    label: const Text('Create new list', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Done', style: TextStyle(color: context.palette.textSecondary)),
        ),
      ],
    );
  }
}

/// Minimal single-field dialog for naming a new list.
class _QuickNameDialog extends StatefulWidget {
  const _QuickNameDialog();

  @override
  State<_QuickNameDialog> createState() => _QuickNameDialogState();
}

class _QuickNameDialogState extends State<_QuickNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.palette.backgroundElevated,
      title: Text('New List', style: TextStyle(color: context.palette.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: context.palette.textPrimary),
        decoration: InputDecoration(
          hintText: 'List name',
          hintStyle: TextStyle(color: context.palette.textMuted),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.palette.textMuted)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
