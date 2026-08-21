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

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fillColor = disabled ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent;
    final Gradient? gradient = disabled
        ? null
        : isDark
            ? AppColors.silverGradient
            : const LinearGradient(colors: [AppColors.brand, AppColors.positive], begin: Alignment.centerLeft, end: Alignment.centerRight);

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? fillColor : null,
          borderRadius: BorderRadius.circular(27),
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
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
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
                    // dark mode: black text on silver | light mode: white text on the gradient
                    color: isDark ? AppColors.black : AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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
