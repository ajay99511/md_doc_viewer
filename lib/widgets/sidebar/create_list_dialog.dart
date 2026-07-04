import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../utils/palette.dart';

/// Dialog to create a new file list.
class CreateListDialog extends ConsumerStatefulWidget {
  const CreateListDialog({super.key});

  @override
  ConsumerState<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends ConsumerState<CreateListDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.palette.backgroundElevated,
      title: Text(
        'Create New List',
        style: TextStyle(color: context.palette.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g., Project Docs, Learning Resources',
                hintStyle: TextStyle(color: context.palette.textMuted),
                labelStyle: TextStyle(color: context.palette.textSecondary),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this list for?',
                hintStyle: TextStyle(color: context.palette.textMuted),
                labelStyle: TextStyle(color: context.palette.textSecondary),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.palette.textMuted)),
        ),
        // Rebuilds as the user types so the button enables correctly.
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) {
            final canCreate = _nameController.text.trim().isNotEmpty;
            return FilledButton(
              onPressed: !canCreate
                  ? null
                  : () {
                      ref.read(listsProvider.notifier).create(
                            name: _nameController.text.trim(),
                            description: _descController.text.trim().isEmpty
                                ? null
                                : _descController.text.trim(),
                          );
                      Navigator.pop(context);
                    },
              child: const Text('Create'),
            );
          },
        ),
      ],
    );
  }
}
