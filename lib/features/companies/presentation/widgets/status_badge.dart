import 'package:flutter/material.dart';
import 'package:brixen/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isActive;

  const StatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accentEmerald.withValues(alpha: 0.12)
            : AppColors.accentRose.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.accentEmerald.withValues(alpha: 0.35)
              : AppColors.accentRose.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.accentEmerald : AppColors.accentRose,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.accentEmerald : AppColors.accentRose,
            ),
          ),
        ],
      ),
    );
  }
}
