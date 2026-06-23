import 'package:flutter/material.dart';
import '../../core/constants/finder_colors.dart';

/// Custom Divider with Text - Reusable component
class CustomDivider extends StatelessWidget {
  final String text;

  const CustomDivider({super.key, this.text = 'or'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: FinderColors.textSecondary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: FinderColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: FinderColors.textSecondary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
