import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// "42/60"-style counter shown under a title/message field with a hard
/// character cap — turns warn-colored once the limit is close.
class CharacterCounter extends StatelessWidget {
  final int current;
  final int max;
  const CharacterCounter({super.key, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final nearLimit = current >= (max * 0.9).round();
    final overLimit = current > max;
    final color = overLimit
        ? AppColors.accentRose
        : nearLimit
            ? AppColors.accentGold
            : AppColors.textHint;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$current/$max',
        style: TextStyle(fontSize: 11, color: color, fontWeight: nearLimit ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}
