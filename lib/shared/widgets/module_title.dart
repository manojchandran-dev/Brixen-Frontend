import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A module page's app-bar title: the name, bold, with an optional one-line
/// [subtitle] underneath.
class ModuleTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ModuleTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
