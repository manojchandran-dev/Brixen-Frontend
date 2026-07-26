import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrixenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const BrixenButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return isOutlined
        ? _OutlinedBtn(label: label, onPressed: onPressed, isLoading: isLoading)
        : _FilledBtn(label: label, onPressed: onPressed, isLoading: isLoading);
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _FilledBtn({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  static const _darkBtn = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fillColor = disabled
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : isDark
            ? Colors.transparent   // gradient handles fill in dark
            : _darkBtn;            // near-black in light — elite contrast on silver bg

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: (!disabled && isDark) ? AppColors.silverGradient : null,
          color: (!disabled && isDark) ? null : fillColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled
              ? null
              : isDark
                  ? [
                      BoxShadow(
                        color: AppColors.silver.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      // deep shadow — makes near-black button "float" on silver bg
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.30),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.10),
                        blurRadius: 40,
                        offset: const Offset(0, 14),
                      ),
                    ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.black : AppColors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    // dark mode: black text on silver | light mode: white text on near-black
                    color: isDark ? AppColors.black : AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _OutlinedBtn({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: primary.withValues(alpha: 0.45), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}
