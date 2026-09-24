import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A generic yes/no confirmation dialog — every feature used to hand-roll
/// its own `showDialog(AlertDialog(...))` for this (see Sales/Products
/// delete flows); this consolidates that into one reusable call.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dCtx) => AlertDialog(
      backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dCtx).pop(false),
          child: Text(cancelLabel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dCtx).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: isDestructive ? AppColors.accentRose : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
