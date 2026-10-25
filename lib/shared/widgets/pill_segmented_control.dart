import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// One option of a [PillSegmentedControl].
class PillSegment<T> {
  final T value;
  final String label;
  final IconData? icon;

  /// Optional count shown as a small badge after the label.
  final int? count;
  const PillSegment({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });
}

/// Themed two-or-more-way switch: a soft track with a brand-gradient thumb
/// that slides to the selected option (same gradient as the app bar's +
/// button, so it follows light/dark). [onChanged] null = read-only.
class PillSegmentedControl<T> extends StatelessWidget {
  final List<PillSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final double height;

  const PillSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    this.onChanged,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final index = segments.indexWhere((s) => s.value == value).clamp(0, 99);
    final enabled = onChanged != null;
    final selectedFg = isDark ? AppColors.black : AppColors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth / segments.length;
            return Stack(
              children: [
                // Sliding thumb.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: w * index,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.silverGradient
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.brand, AppColors.brandDeep],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.brand.withValues(
                            alpha: isDark ? 0 : 0.35,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final s in segments)
                      Expanded(
                        child: _SegmentLabel(
                          segment: s,
                          selected: s.value == value,
                          selectedFg: selectedFg,
                          onTap: enabled && s.value != value
                              ? () => onChanged!(s.value)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  final PillSegment<T> segment;
  final bool selected;
  final Color selectedFg;
  final VoidCallback? onTap;

  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.selectedFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? selectedFg : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (segment.icon != null) ...[
                  Icon(segment.icon, size: 17, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (segment.count != null) ...[
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? selectedFg.withValues(alpha: 0.22)
                          : AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${segment.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected ? selectedFg : AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
