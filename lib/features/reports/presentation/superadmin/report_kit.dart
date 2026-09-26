import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton.dart';
import 'report_date_range_sheet.dart';
import 'superadmin_reports_data.dart';

// Shared building blocks for the superadmin report pages, so all six look
// and behave alike: header + date filter, summary tiles, one trend chart,
// one breakdown/list.

/// One report's tab on the Reports page: the date filter, then [body]
/// built once the report's data is ready.
class ReportPage extends StatelessWidget {
  final ReportPeriod range;
  final ValueChanged<ReportPeriod> onRange;
  final bool loading;

  /// Shown (with retry) when the report's data failed to load.
  final Object? error;
  final VoidCallback onRetry;
  final List<Widget> Function() body;

  const ReportPage({
    super.key,
    required this.range,
    required this.onRange,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RangeChips(range: range, onRange: onRange),
        _ScopeLegend(range),
        Expanded(
          child: error != null && !loading
              ? ErrorCard(error: error!, onRetry: onRetry)
              : loading
              ? const SkeletonListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 110),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRetry(),
                  child: _Period(
                    period: range,
                    child: ListView(
                      // Bottom room for the floating nav bar.
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                      children: [
                        for (final w in body()) ...[
                          w,
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RangeChips extends StatelessWidget {
  final ReportPeriod range;
  final ValueChanged<ReportPeriod> onRange;
  const _RangeChips({required this.range, required this.onRange});

  Future<void> _pickCustom(BuildContext context) async {
    // Bottom sheet (quick picks + calendar), not a full-screen page.
    final picked = await showReportDateRangeSheet(
      context,
      initial: range.custom,
    );
    if (picked != null) onRange(ReportPeriod(ReportRange.custom, picked));
  }

  // Secondary filter: slim underline tabs in green — distinct from the
  // blue report tabs above.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            for (final r in ReportRange.values)
              Expanded(
                // The custom chip shows its dates, so it gets more room.
                flex:
                    r == ReportRange.custom && range.range == ReportRange.custom
                    ? 2
                    : 1,
                child: InkWell(
                  onTap: () => r == ReportRange.custom
                      ? _pickCustom(context)
                      : onRange(ReportPeriod(r)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (r == ReportRange.custom) ...[
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: r == range.range
                                    ? AppColors.positive
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                r == ReportRange.custom &&
                                        range.range == ReportRange.custom
                                    ? range.label
                                    : ReportPeriod(r).label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: r == range.range
                                      ? AppColors.positive
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: r == range.range
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: r == range.range
                              ? AppColors.positive
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One summary tile.
class ReportStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  /// True when the number ignores the date filter (e.g. total companies).
  final bool allTime;
  const ReportStat(
    this.icon,
    this.label,
    this.value,
    this.color, {
    this.allTime = false,
  });
}

/// Summary tiles, two per row, filled with their colour.
class ReportSummary extends StatelessWidget {
  final List<ReportStat> stats;
  const ReportSummary(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StatTile(stats[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < stats.length
                    ? _StatTile(stats[i + 1])
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < stats.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

/// Hands the selected period down to every [ReportScopeTag] in a report.
class _Period extends InheritedWidget {
  final ReportPeriod period;
  const _Period({required this.period, required super.child});

  @override
  bool updateShouldNotify(_Period old) => old.period != period;
}

/// Says what a number covers: the selected period (green, calendar) or all
/// time (grey, infinity — ignores the date filter). [onColor] = drawn on a
/// coloured summary tile instead of a white card.
class ReportScopeTag extends StatelessWidget {
  final bool allTime;
  final Color? onColor;
  const ReportScopeTag({super.key, required this.allTime, this.onColor});

  @override
  Widget build(BuildContext context) {
    final period = context
        .dependOnInheritedWidgetOfExactType<_Period>()
        ?.period;
    final text = allTime ? 'All time' : (period?.label ?? 'Period');
    final tile = onColor != null;
    // On a tile: filtered = solid white pill, all time = faint pill.
    final (Color bg, Color fg) = switch ((tile, allTime)) {
      (true, false) => (Colors.white, onColor!),
      (true, true) => (Colors.white.withValues(alpha: 0.2), Colors.white),
      (false, false) => (
        AppColors.positive.withValues(alpha: 0.14),
        AppColors.positive,
      ),
      (false, true) => (AppColors.surfaceElevated, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allTime
                ? Icons.all_inclusive_rounded
                : Icons.calendar_month_rounded,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line under the date filter explaining the two tags.
class _ScopeLegend extends StatelessWidget {
  final ReportPeriod range;
  const _ScopeLegend(this.range);

  @override
  Widget build(BuildContext context) {
    final hint = TextStyle(color: AppColors.textHint, fontSize: 11);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _Period(
        period: range,
        // Wraps to two lines on narrow screens / large text.
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (allTime, text) in const [
              (false, 'follows filter'),
              (true, 'ignores filter'),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReportScopeTag(allTime: allTime),
                  const SizedBox(width: 4),
                  Text(text, style: hint),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final ReportStat stat;
  const _StatTile(this.stat);

  @override
  Widget build(BuildContext context) {
    final c = stat.color;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(c),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: Color.lerp(c, Colors.black, 0.3)!.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Large faded icon in the corner for depth.
            Positioned(
              right: -10,
              bottom: -14,
              child: Icon(
                stat.icon,
                size: 72,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(stat.icon, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 6),
                      const Spacer(),
                      Flexible(
                        flex: 6,
                        child: ReportScopeTag(
                          allTime: stat.allTime,
                          onColor: c,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White card with an icon badge, title and caption — the frame for charts
/// and lists. The badge follows the content (bar chart / donut / list), and
/// a trend chart also gets its total as a pill.
class ReportCard extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget child;

  /// True when the card ignores the date filter.
  final bool allTime;
  const ReportCard({
    super.key,
    required this.title,
    this.caption,
    required this.child,
    this.allTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = child;
    final icon = switch (c) {
      ReportTrendChart() => Icons.bar_chart_rounded,
      ReportBreakdown() => Icons.donut_large_rounded,
      _ => Icons.list_alt_rounded,
    };
    final total = c is ReportTrendChart
        ? c.buckets.fold<int>(0, (a, b) => a + b.count)
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.highlightShadow(0.9),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AppColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(child: ReportScopeTag(allTime: allTime)),
                        if (caption != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            flex: 2,
                            child: Text(
                              caption!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (total != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total total',
                    style: const TextStyle(
                      color: AppColors.positive,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Bar chart of [buckets] on a solid green panel: solid blue bars (the
/// latest strongest), faint grid lines for scale, values on top.
class ReportTrendChart extends StatelessWidget {
  final List<TrendBucket> buckets;

  /// Kept for call sites; the chart uses the theme's green/blue pairing.
  final Color color;
  const ReportTrendChart({
    super.key,
    required this.buckets,
    this.color = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.every((b) => b.count == 0)) {
      return const ReportEmpty('Nothing in this period');
    }
    final max = buckets.fold<int>(1, (a, b) => b.count > a ? b.count : a);
    // Label every bar when few, otherwise about six evenly spaced.
    final labelEvery = buckets.length <= 8 ? 1 : (buckets.length / 6).ceil();
    const chartHeight = 130.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.positive,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                // Grid lines at 1/3 and 2/3 height.
                for (final f in const [0.33, 0.66])
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 4 + (chartHeight - 26) * f,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < buckets.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (buckets[i].count > 0)
                              Text(
                                '${buckets[i].count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            const SizedBox(height: 3),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height:
                                  4 +
                                  (buckets[i].count / max) * (chartHeight - 30),
                              decoration: BoxDecoration(
                                color: i == buckets.length - 1
                                    ? AppColors.brandDeep
                                    : AppColors.brand.withValues(alpha: 0.75),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < buckets.length; i++)
                Expanded(
                  child: Text(
                    i % labelEvery == 0 || i == buckets.length - 1
                        ? buckets[i].label
                        : '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One slice of a breakdown: label, count and its colour.
class BreakdownItem {
  final String label;
  final int count;
  final Color color;
  const BreakdownItem(this.label, this.count, this.color);
}

/// Donut ring (total in the middle) with a legend: dot, label, count and a
/// percentage pill per slice.
class ReportBreakdown extends StatelessWidget {
  final List<BreakdownItem> items;
  const ReportBreakdown(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (a, b) => a + b.count);
    if (total == 0) return const ReportEmpty('Nothing in this period');
    return Row(
      children: [
        SizedBox(
          width: 108,
          height: 108,
          child: CustomPaint(
            painter: _DonutPainter(items, total, AppColors.border),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    'total',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: it.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${it.count}',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: it.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(it.count * 100 / total).round()}%',
                          style: TextStyle(
                            color: it.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<BreakdownItem> items;
  final int total;
  final Color track;
  _DonutPainter(this.items, this.total, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, 6.2832, false, paint..color = track);
    final slices = items.where((i) => i.count > 0).toList();
    const gap = 0.04; // small gap between slices
    var start = -1.5708; // 12 o'clock
    for (final it in slices) {
      final sweep = 6.2832 * it.count / total;
      canvas.drawArc(
        rect,
        start + (slices.length > 1 ? gap / 2 : 0),
        sweep - (slices.length > 1 ? gap : 0),
        false,
        paint..color = it.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.items != items || old.total != total;
}

/// A list row inside a report card: a soft rounded tile.
class ReportRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  const ReportRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailing!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportEmpty extends StatelessWidget {
  final String text;
  const ReportEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(
      child: Text(
        text,
        style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
      ),
    ),
  );
}

/// Soft note for figures the backend doesn't provide yet.
class ReportNote extends StatelessWidget {
  final String text;
  const ReportNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.brand,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
