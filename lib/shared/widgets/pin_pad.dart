import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PinPad extends StatefulWidget {
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

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  // Eye key (left of 0): show the typed digits instead of dots.
  bool _show = false;

  String get pin => widget.pin;
  int get maxLength => widget.maxLength;
  bool get isLoading => widget.isLoading;
  String? get errorText => widget.errorText;
  ValueChanged<String> get onChanged => widget.onChanged;
  VoidCallback? get onSubmit => widget.onSubmit;

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
    final isEye = k.isEmpty;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.highlightShadow(0.9),
            blurRadius: 6,
            offset: const Offset(-3, -3),
          ),
        ]),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: isEye
              ? () => setState(() => _show = !_show)
              : isBack
              ? _onBackspace
              : () => _onKey(k),
          customBorder: const CircleBorder(),
          splashColor: AppColors.brand.withValues(alpha: 0.12),
          highlightColor: AppColors.brand.withValues(alpha: 0.08),
          child: Center(
            child: isEye
                ? Icon(
                    _show
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.brand,
                    size: 22,
                    semanticLabel: _show ? 'Hide PIN' : 'Show PIN',
                  )
                : isBack
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.brand,
                    size: 20,
                  )
                : Text(
                    k,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
          ),
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
        SizedBox(
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxLength, (i) {
              final filled = i < pin.length;
              if (filled && _show) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 22,
                  alignment: Alignment.center,
                  child: Text(
                    pin[i],
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                );
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: filled
                      ? const LinearGradient(
                          colors: [AppColors.brand, AppColors.positive],
                        )
                      : null,
                  color: filled ? null : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? Colors.transparent
                        : AppColors.brand.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: filled
                      ? AppColors.shadows([
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ])
                      : null,
                ),
              );
            }),
          ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand,
                    ),
                  ),
                )
              : errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
              children: rows
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row
                            .map(
                              (k) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                ),
                                child: _buildKey(k, context),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
