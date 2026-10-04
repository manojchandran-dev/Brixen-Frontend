import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'chip_filter_sheet.dart';

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

/// Search box (with its ✕) plus a filter button — the header every module
/// list uses. [filterActive] fills the button while a filter is applied.
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool filterActive;

  /// Null = no filter button.
  final VoidCallback? onFilter;

  /// More square buttons after the filter, e.g. restore deleted items.
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    required this.filterActive,
    this.onFilter,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: controller,
              hintText: hintText,
              onChanged: onChanged,
            ),
          ),
          if (onFilter != null) ...[
            const SizedBox(width: 10),
            HeaderIconButton(
              tooltip: 'Filter',
              icon: Icons.filter_list_rounded,
              active: filterActive,
              onTap: onFilter!,
            ),
          ],
          for (final a in actions) ...[const SizedBox(width: 10), a],
        ],
      ),
    );
  }
}

/// Filter options from a loaded list's distinct values — so a filter only
/// ever offers values that exist. "on_leave" → "On leave".
List<(Object, String)> distinctOptions<T>(
  Iterable<T> items,
  String? Function(T) valueOf,
) {
  final values = <String>{
    for (final i in items)
      if (valueOf(i) case final v? when v.trim().isNotEmpty) v,
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [
    for (final v in values)
      (v, (v[0].toUpperCase() + v.substring(1)).replaceAll('_', ' ')),
  ];
}
