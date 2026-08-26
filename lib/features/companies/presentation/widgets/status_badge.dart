import 'package:flutter/material.dart';
import 'package:brixen/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isActive;
  // Use on a colored (blue/green) card background — swaps to a white pill
  // with colored text/dot instead of a solid fill, for contrast.
  final bool inverse;

  const StatusBadge({super.key, required this.isActive, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? AppColors.positive : AppColors.brandBlack;
    final bg = inverse ? AppColors.white : statusColor;
    final fg = inverse ? statusColor : AppColors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        gradient: inverse
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.accentGradient(bg)),
        color: inverse ? bg : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: inverse
            ? AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))])
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fg.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(
              isActive ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: fg,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
