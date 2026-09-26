import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// "Total Companies  (3)" row above a module's list — the label on the
/// left, the count in a brand pill on the right.
class ListCountBar extends StatelessWidget {
  final String label;
  final int count;
  final EdgeInsetsGeometry padding;
  const ListCountBar({
    super.key,
    required this.label,
    required this.count,
    this.padding = const EdgeInsets.fromLTRB(16, 2, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
