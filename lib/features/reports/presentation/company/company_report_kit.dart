import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/search_field.dart';
import '../superadmin/report_kit.dart';
import '../superadmin/superadmin_reports_data.dart';

// Building blocks for the company reports: the shared date filter, the
// report screen frame, and a searchable/sortable detail list. Cards, tiles,
// charts and donuts come from the shared report kit.

/// The Reports date range — shared by every report tab.
final companyReportPeriodProvider = StateProvider<ReportPeriod>(
  (ref) => const ReportPeriod(ReportRange.month),
);

/// One report tab: the date filter (shared across tabs), then [body]
/// (loading / error handled).
class CompanyReportScreen extends ConsumerWidget {
  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final List<Widget> Function(ReportPeriod period) body;

  const CompanyReportScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(companyReportPeriodProvider);
    return ReportPage(
      range: period,
      onRange: (p) => ref.read(companyReportPeriodProvider.notifier).state = p,
      loading: loading,
      error: error,
      onRetry: onRetry,
      body: () => body(period),
    );
  }
}

/// One sort choice for a [ReportList].
class ReportSort<T> {
  final String label;
  final int Function(T a, T b) compare;
  const ReportSort(this.label, this.compare);
}

/// Detail list inside a report card: optional search, a sort menu, and the
/// first 25 rows with "Show more".
class ReportList<T> extends StatefulWidget {
  final String title;
  final String? caption;
  final List<T> items;
  final String Function(T)? searchText;
  final String searchHint;
  final List<ReportSort<T>> sorts;
  final Widget Function(T item, int index) row;
  final String emptyText;
  final bool allTime;

  const ReportList({
    super.key,
    required this.title,
    required this.items,
    required this.row,
    this.caption,
    this.searchText,
    this.searchHint = 'Search',
    this.sorts = const [],
    this.emptyText = 'Nothing in this period',
    this.allTime = false,
  });

  @override
  State<ReportList<T>> createState() => _ReportListState<T>();
}

class _ReportListState<T> extends State<ReportList<T>> {
  final _search = TextEditingController();
  int _sort = 0;
  int _shown = 25;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final items = [
      for (final it in widget.items)
        if (q.isEmpty ||
            (widget.searchText?.call(it).toLowerCase().contains(q) ?? true))
          it,
    ];
    if (widget.sorts.isNotEmpty) items.sort(widget.sorts[_sort].compare);

    return ReportCard(
      title: widget.title,
      caption: widget.caption,
      allTime: widget.allTime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.searchText != null || widget.sorts.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (widget.searchText != null)
                    Expanded(
                      child: SearchField(
                        controller: _search,
                        hintText: widget.searchHint,
                        onChanged: (_) => setState(() => _shown = 25),
                      ),
                    )
                  else
                    const Spacer(),
                  if (widget.sorts.length > 1) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<int>(
                      tooltip: 'Sort',
                      initialValue: _sort,
                      onSelected: (i) => setState(() => _sort = i),
                      itemBuilder: (_) => [
                        for (final (i, s) in widget.sorts.indexed)
                          PopupMenuItem(value: i, child: Text(s.label)),
                      ],
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sort_rounded,
                              size: 18,
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.sorts[_sort].label,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (items.isEmpty)
            ReportEmpty(q.isEmpty ? widget.emptyText : 'No matches')
          else ...[
            for (final (i, it) in items.take(_shown).indexed) widget.row(it, i),
            if (items.length > _shown)
              TextButton(
                onPressed: () => setState(() => _shown += 25),
                child: Text('Show more (${items.length - _shown} left)'),
              ),
          ],
        ],
      ),
    );
  }
}
