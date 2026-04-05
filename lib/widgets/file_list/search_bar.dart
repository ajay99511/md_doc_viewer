import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../utils/constants.dart';

/// Search bar for filtering files in the current folder.
class SearchBarWidget extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    required this.query,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search in folder...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: onChanged,
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.x,
                size: 16,
                color: AppColors.textMuted,
              ),
              onPressed: onClear ?? () => onChanged(''),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
