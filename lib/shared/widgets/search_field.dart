import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The inline search bar styling every list page (Sales, Products, ...) has
/// been hand-rolling separately — pulled out once so new lists don't
/// duplicate it a third/fourth time.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.highlightShadow(0.85),
                  blurRadius: 6,
                  offset: const Offset(-3, -3),
                ),
              ],
      ),
      // Rebuilds with the text so the ✕ shows only while there's a query.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: Icon(
                      Icons.close_rounded,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.clear();
                      // Tell the page, so it re-runs its search.
                      onChanged?.call('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}
