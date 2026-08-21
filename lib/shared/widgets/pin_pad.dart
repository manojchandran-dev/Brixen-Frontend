import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PinPad extends StatelessWidget {
  final String pin;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;
  final String? errorText;
  final bool isLoading;

  const PinPad({
    super.key,
    required this.pin,
    this.maxLength = 4,
    required this.onChanged,
    this.onSubmit,
    this.errorText,
    this.isLoading = false,
  });

  void _onKey(String digit) {
    if (isLoading) return;
    if (pin.length < maxLength) {
      final next = pin + digit;
      onChanged(next);
      if (next.length == maxLength) onSubmit?.call();
    }
  }

  void _onBackspace() {
    if (isLoading) return;
    if (pin.isNotEmpty) onChanged(pin.substring(0, pin.length - 1));
  }

  Widget _buildKey(String k, BuildContext context) {
    final isBack = k == '⌫';
    final isEmpty = k.isEmpty;
    if (isEmpty) return const SizedBox(width: 76, height: 76);
    return GestureDetector(
      onTap: isBack ? _onBackspace : () => _onKey(k),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isBack
              ? const Icon(Icons.backspace_outlined, color: AppColors.brand, size: 22)
              : Text(k,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: filled ? const LinearGradient(colors: [AppColors.brand, AppColors.positive]) : null,
                color: filled ? null : Colors.transparent,
                border: Border.all(
                  color: filled ? Colors.transparent : AppColors.brand.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.35),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),

        // Error label / loading indicator
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                  ),
                )
              : errorText != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorText!,
                        style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    )
                  : const SizedBox(height: 12),
        ),

        const SizedBox(height: 26),

        // Number grid
        Opacity(
          opacity: isLoading ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: isLoading,
            child: Column(
              children: rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row
                        .map((k) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              child: _buildKey(k, context),
                            ))
                        .toList(),
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
