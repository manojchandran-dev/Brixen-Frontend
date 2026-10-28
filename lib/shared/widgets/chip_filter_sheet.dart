import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// Square icon button beside a search box (filter, trash…). [active]
/// fills it with the brand colour, e.g. while a filter is applied.
class HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const HeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadows([
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
            ]),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.brand,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// A date filter: [from] to [to], both days included. [label] is what its
/// chip says ("Last 7 days", or the custom range's dates).
class DateFilter {
  final DateTime from, to;
  final String label;
  const DateFilter(this.from, this.to, this.label);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Today, Last 7 days, Last 30 days, This month — as of [now].
  static List<DateFilter> presets([DateTime? now]) {
    final today = _day(now ?? DateTime.now());
    return [
      DateFilter(today, today, 'Today'),
      DateFilter(today.subtract(const Duration(days: 6)), today, 'Last 7 days'),
      DateFilter(
        today.subtract(const Duration(days: 29)),
        today,
        'Last 30 days',
      ),
      DateFilter(DateTime(today.year, today.month), today, 'This month'),
    ];
  }

  /// A picked range, labelled with its dates.
  factory DateFilter.custom(DateTimeRange r) {
    final f = DateFormat('d MMM yy');
    final from = _day(r.start), to = _day(r.end);
    return DateFilter(
      from,
      to,
      from == to ? f.format(from) : '${f.format(from)} – ${f.format(to)}',
    );
  }

  bool get isCustom => !presets().any((p) => p == this);

  /// The API's ?from=&to=.
  Map<String, String> get params {
    final f = DateFormat('yyyy-MM-dd');
    return {'from': f.format(from), 'to': f.format(to)};
  }

  @override
  bool operator ==(Object other) =>
      other is DateFilter && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// A filter sheet's choices as API query params: a [DateFilter] becomes
/// from / to, anything else its text; unset (null) ones are left out.
Map<String, String> filterQueryParams(Map<String, Object?> filters) => {
  for (final e in filters.entries)
    if (e.value is DateFilter)
      ...(e.value as DateFilter).params
    else if (e.value != null)
      e.key: '${e.value}',
};

/// One section of a [showChipFilterSheet]: a title and its options as
/// (value, label) pairs. [key] names it in the selected/applied maps.
class FilterSection {
  final String key;
  final String title;
  final List<(Object, String)> options;

  /// A date section ([FilterSection.dates]): the presets plus a custom
  /// range picker; its value is a [DateFilter].
  final bool isDate;
  const FilterSection({
    required this.key,
    required this.title,
    required this.options,
  }) : isDate = false;

  /// Date-wise: Today, Last 7 days, Last 30 days, This month, or a custom
  /// range.
  const FilterSection.dates({required this.key, this.title = 'Date'})
    : options = const [],
      isDate = true;
}

/// Bottom panel of chip filters: one row of chips per [FilterSection],
/// "All" first. Chip taps edit a draft; "Apply filters" hands [onApply] the
/// chosen value per section key (null = All), "Clear all" calls [onClear].
/// Both close the panel. A section with fewer than two options is hidden —
/// it can't narrow anything — unless it has a value selected.
void showChipFilterSheet(
  BuildContext context, {
  required String title,
  required List<FilterSection> sections,
  required Map<String, Object?> selected,
  required ValueChanged<Map<String, Object?>> onApply,
  required VoidCallback onClear,
}) {
  final draft = Map<String, Object?>.of(selected);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (_, setSheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  children: [
                    for (final section in sections)
                      if (section.isDate ||
                          section.options.length >= 2 ||
                          draft[section.key] != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            section.title.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipPill(
                              label: 'All',
                              selected: draft[section.key] == null,
                              onTap: () =>
                                  setSheet(() => draft[section.key] = null),
                            ),
                            if (section.isDate) ...[
                              for (final p in DateFilter.presets())
                                _ChipPill(
                                  label: p.label,
                                  selected: draft[section.key] == p,
                                  onTap: () => setSheet(
                                    () => draft[section.key] =
                                        draft[section.key] == p ? null : p,
                                  ),
                                ),
                              _ChipPill(
                                label: switch (draft[section.key]) {
                                  final DateFilter d when d.isCustom =>
                                    d.label,
                                  _ => 'Custom dates…',
                                },
                                icon: Icons.date_range_rounded,
                                selected: switch (draft[section.key]) {
                                  final DateFilter d => d.isCustom,
                                  _ => false,
                                },
                                onTap: () async {
                                  final now = DateTime.now();
                                  final current = draft[section.key];
                                  final picked = await showDateRangePicker(
                                    context: sheetCtx,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(now.year + 1, 12, 31),
                                    initialDateRange: current is DateFilter
                                        ? DateTimeRange(
                                            start: current.from,
                                            end: current.to,
                                          )
                                        : null,
                                  );
                                  if (picked != null) {
                                    setSheet(
                                      () => draft[section.key] =
                                          DateFilter.custom(picked),
                                    );
                                  }
                                },
                              ),
                            ],
                            for (final (value, label) in section.options)
                              _ChipPill(
                                label: label,
                                selected: draft[section.key] == value,
                                onTap: () => setSheet(
                                  () => draft[section.key] =
                                      draft[section.key] == value
                                      ? null
                                      : value,
                                ),
                              ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brand,
                            side: const BorderSide(color: AppColors.brand),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            onClear();
                            Navigator.of(sheetCtx).pop();
                          },
                          child: const Text(
                            'Clear all',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            onApply(draft);
                            Navigator.of(sheetCtx).pop();
                          },
                          child: const Text(
                            'Apply filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ChipPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChipPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brand : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.brand,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
