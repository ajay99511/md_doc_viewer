import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyState({
    super.key,
    this.message = 'Select a file to view',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.description_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
