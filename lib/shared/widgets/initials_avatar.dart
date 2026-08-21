import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

const List<Color> _avatarPalette = [
  AppColors.accentIndigo,
  AppColors.accentEmerald,
  AppColors.accentTeal,
  AppColors.accentGold,
  AppColors.accentRose,
  AppColors.accentViolet,
  AppColors.accentSlate,
];

/// Deterministically maps [seed] (e.g. a person's name) to one of the app's
/// accent colors, so the same name always gets the same color and different
/// names are spread across the palette.
Color avatarColorFor(String seed) {
  if (seed.isEmpty) return _avatarPalette.last;
  final hash = seed.trim().toLowerCase().codeUnits.fold<int>(0, (acc, c) => acc + c);
  return _avatarPalette[hash % _avatarPalette.length];
}

/// Solid-fill circle avatar with the first letter of [seed] centered in
/// white — color is unique per [seed] via [avatarColorFor].
class InitialsAvatar extends StatelessWidget {
  final String seed;
  final double size;
  const InitialsAvatar({super.key, required this.seed, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(seed);
    final letter = seed.trim().isNotEmpty ? seed.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
