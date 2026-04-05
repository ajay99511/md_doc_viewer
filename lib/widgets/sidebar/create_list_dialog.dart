import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

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
      backgroundColor: AppColors.backgroundElevated,
      title: const Text(
        'Create New List',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g., Project Docs, Learning Resources',
                hintStyle: TextStyle(color: AppColors.textMuted),
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this list for?',
                hintStyle: TextStyle(color: AppColors.textMuted),
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        Consumer(
          builder: (context, ref, _) {
            return FilledButton(
              onPressed: _nameController.text.trim().isEmpty
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
