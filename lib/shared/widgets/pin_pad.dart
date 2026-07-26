import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PinPad extends StatelessWidget {
  final String pin;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;
  final String? errorText;

  const PinPad({
    super.key,
    required this.pin,
    this.maxLength = 4,
    required this.onChanged,
    this.onSubmit,
    this.errorText,
  });

  void _onKey(String digit) {
    if (pin.length < maxLength) {
      final next = pin + digit;
      onChanged(next);
      if (next.length == maxLength) onSubmit?.call();
    }
  }

  void _onBackspace() {
    if (pin.isNotEmpty) onChanged(pin.substring(0, pin.length - 1));
  }

  Widget _buildKey(String k, BuildContext context) {
    final isBack = k == '⌫';
    final isEmpty = k.isEmpty;
    if (isEmpty) return const SizedBox(width: 80, height: 80);
    return GestureDetector(
      onTap: isBack ? _onBackspace : () => _onKey(k),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Center(
          child: isBack
              ? Icon(Icons.backspace_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22)
              : Text(k,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxLength, (i) {
            final filled = i < pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.silver : Colors.transparent,
                border: Border.all(
                  color: filled ? AppColors.silver : AppColors.silverDark,
                  width: 2,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppColors.silver.withValues(alpha: 0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),

        // Error label
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorText!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                )
              : const SizedBox(height: 12),
        ),

        const SizedBox(height: 28),

        // Number grid
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map((k) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildKey(k, context),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
