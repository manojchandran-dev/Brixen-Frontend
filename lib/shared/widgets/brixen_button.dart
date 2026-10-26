import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The app's main button. While an async [onPressed] is still running the
/// button shows its spinner and ignores further taps, so a double tap can
/// never create the same record twice — even where a form forgets to set
/// its own [isLoading].
class BrixenButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? trailingIcon;

  const BrixenButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.trailingIcon,
  });

  @override
  State<BrixenButton> createState() => _BrixenButtonState();
}

class _BrixenButtonState extends State<BrixenButton> {
  bool _busy = false;

  Future<void> _press() async {
    if (_busy) return;
    // An `async` handler passed as a VoidCallback still returns its Future.
    final Object? result = (widget.onPressed as dynamic)();
    if (result is! Future) return;
    setState(() => _busy = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null ? null : _press;
    final loading = widget.isLoading || _busy;
    return widget.isOutlined
        ? _OutlinedBtn(
            label: widget.label,
            onPressed: onPressed,
            isLoading: loading,
          )
        : _FilledBtn(
            label: widget.label,
            onPressed: onPressed,
            isLoading: loading,
            trailingIcon: widget.trailingIcon,
          );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const _FilledBtn({
    required this.label,
    required this.isLoading,
    this.onPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fillColor = disabled
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.transparent;
    final Gradient? gradient = disabled
        ? null
        : isDark
        ? AppColors.silverGradient
        : const LinearGradient(
            colors: [AppColors.brand, AppColors.positive],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

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
              : AppColors.shadows([
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]),
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
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        // dark mode: black text on silver | light mode: white text on the gradient
                        color: isDark ? AppColors.black : AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        trailingIcon,
                        size: 18,
                        color: isDark ? AppColors.black : AppColors.white,
                      ),
                    ],
                  ],
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
          border: Border.all(
            color: primary.withValues(alpha: 0.45),
            width: 1.5,
          ),
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
