import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../utils/constants.dart';

/// A single file item in the file list panel.
class FileListItem extends StatelessWidget {
  final String name;
  final DateTime? lastModified;
  final bool isSelected;
  final VoidCallback onTap;

  const FileListItem({
    super.key,
    required this.name,
    this.lastModified,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.backgroundActive : Colors.transparent,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 18,
              color: isSelected ? AppColors.accent : AppColors.fileIcon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lastModified != null)
                    Text(
                      _formatDate(lastModified!),
                      style: TextStyle(
                        color: isSelected ? AppColors.textSecondary : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
