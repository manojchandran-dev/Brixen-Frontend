import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../domain/entities/reports_summary.dart';
import '../providers/reports_provider.dart';

enum _Period { weekly, monthly, yearly, custom }

class _Bucket {
  final DateTime start;
  final DateTime endExclusive;
  final String label;
  const _Bucket(this.start, this.endExclusive, this.label);
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(endExclusive);
}

class ReportsBody extends ConsumerStatefulWidget {
  const ReportsBody({super.key});

  @override
  ConsumerState<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<ReportsBody> {
  _Period _period = _Period.weekly;
  DateTimeRange? _customRange;

  static final _fmtMoney = NumberFormat('#,##,##0', 'en_IN');
  static final _fmtDay = DateFormat('d MMM');

  DateTimeRange get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.weekly:
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      case _Period.monthly:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
      case _Period.yearly:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case _Period.custom:
        return _customRange ?? DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
    }
  }

  String get _rangeLabel {
    final r = _range;
    if (_period == _Period.yearly) return '${r.start.year}';
    if (r.start.year == r.end.year && r.start.month == r.end.month && r.start.day == r.end.day) {
      return _fmtDay.format(r.start);
    }
    return '${_fmtDay.format(r.start)} – ${_fmtDay.format(r.end)}, ${r.end.year}';
  }

  IconData get _periodIcon {
    switch (_period) {
      case _Period.weekly:
        return Icons.calendar_view_week_rounded;
      case _Period.monthly:
        return Icons.calendar_month_rounded;
      case _Period.yearly:
        return Icons.event_repeat_rounded;
      case _Period.custom:
        return Icons.date_range_rounded;
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateRangeSheet(initialRange: _customRange),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = _Period.custom;
      });
    }
  }

  // Splits the active range into chart buckets, sized to keep the bar count
  // readable regardless of which period (or custom span) is selected.
  List<_Bucket> _buildBuckets(DateTimeRange range) {
    switch (_period) {
      case _Period.weekly:
        return List.generate(7, (i) {
          final d = range.start.add(Duration(days: i));
          return _Bucket(d, d.add(const Duration(days: 1)), DateFormat('E').format(d).substring(0, 1));
        });
      case _Period.monthly:
        final daysInMonth = DateTime(range.start.year, range.start.month + 1, 0).day;
        final weekCount = (daysInMonth / 7).ceil();
        return List.generate(weekCount, (i) {
          final start = DateTime(range.start.year, range.start.month, 1 + i * 7);
          final end = i == weekCount - 1
              ? DateTime(range.start.year, range.start.month + 1, 1)
              : start.add(const Duration(days: 7));
          return _Bucket(start, end, 'W${i + 1}');
        });
      case _Period.yearly:
        return List.generate(range.end.month, (i) {
          final start = DateTime(range.start.year, i + 1, 1);
          final end = DateTime(range.start.year, i + 2, 1);
          return _Bucket(start, end, DateFormat('MMM').format(start).substring(0, 1));
        });
      case _Period.custom:
        final spanDays = range.end.difference(range.start).inDays + 1;
        if (spanDays <= 14) {
          return List.generate(spanDays, (i) {
            final d = range.start.add(Duration(days: i));
            return _Bucket(d, d.add(const Duration(days: 1)), DateFormat('d').format(d));
          });
        } else if (spanDays <= 120) {
          final bucketCount = (spanDays / 7).ceil();
          return List.generate(bucketCount, (i) {
            final start = range.start.add(Duration(days: i * 7));
            final end = start.add(const Duration(days: 7));
            return _Bucket(start, end.isAfter(range.end) ? range.end.add(const Duration(days: 1)) : end, 'W${i + 1}');
          });
        } else {
          final months = <_Bucket>[];
          var cursor = DateTime(range.start.year, range.start.month, 1);
          final limit = DateTime(range.end.year, range.end.month + 1, 1);
          while (cursor.isBefore(limit) && months.length < 24) {
            final end = DateTime(cursor.year, cursor.month + 1, 1);
            months.add(_Bucket(cursor, end, DateFormat('MMM').format(cursor).substring(0, 1)));
            cursor = end;
          }
          return months;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final query = ReportsQuery(period: _period.name, from: range.start, to: range.end);
    final summaryAsync = ref.watch(reportsSummaryProvider(query));

    return summaryAsync.when(
      loading: () => const _ReportsSkeleton(),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.textSecondary))),
      data: (summary) => _buildContent(context, range, summary),
    );
  }

  Widget _buildContent(BuildContext context, DateTimeRange range, ReportsSummary summary) {
    final totalSales = summary.salesTotal;
    final totalExpenses = summary.expensesTotal;
    final salesCount = summary.salesCount;
    final expensesCount = summary.expensesCount;
    final profit = summary.netProfit;
    final margin = summary.profitMarginPct;

    // Bucket boundaries only depend on the period/range, not on the data —
    // the backend always returns daily points, so day-level sales/expenses
    // and the running cumulative total are re-aggregated into these same
    // buckets client-side to drive the existing chart widgets unchanged.
    final buckets = _buildBuckets(range);
    final salesByBucket = List<double>.filled(buckets.length, 0);
    final expensesByBucket = List<double>.filled(buckets.length, 0);
    for (final p in summary.salesVsExpenses) {
      final idx = buckets.indexWhere((b) => b.contains(p.date));
      if (idx != -1) {
        salesByBucket[idx] += p.sales;
        expensesByBucket[idx] += p.expenses;
      }
    }

    final sortedCumulative = [...summary.cumulativeProfit]..sort((a, b) => a.date.compareTo(b.date));
    final cumulativeProfit = List<double>.filled(buckets.length, 0);
    int cumPtr = 0;
    double lastCumValue = 0;
    for (int i = 0; i < buckets.length; i++) {
      while (cumPtr < sortedCumulative.length && sortedCumulative[cumPtr].date.isBefore(buckets[i].endExclusive)) {
        lastCumValue = sortedCumulative[cumPtr].value;
        cumPtr++;
      }
      cumulativeProfit[i] = lastCumValue;
    }

    final topCategories = summary.topExpenseCategories.map((c) => MapEntry(c.label, c.amount)).toList();
    final statusEntries = summary.salesByStatus.map((s) => MapEntry(s.status, s.count)).toList();
    final topMethods = summary.salesByPaymentMethod.map((m) => MapEntry(m.label, m.amount)).toList();
    final topCustomers = summary.topCustomers.map((c) => MapEntry(c.label, c.amount)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        _PeriodSelector(
          period: _period,
          onSelect: (p) {
            if (p == _Period.custom) {
              _pickCustomRange();
            } else {
              setState(() => _period = p);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(_rangeLabel, style: TextStyle(fontSize: 12.5, color: AppColors.textHint, fontWeight: FontWeight.w600)),
          if (_period == _Period.custom) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _pickCustomRange,
              child: const Text('Change', style: TextStyle(fontSize: 12.5, color: AppColors.brand, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        const SizedBox(height: 18),

        // ── Profit hero ──────────────────────────────────────────
        // A period-specific watermark icon + soft corner glow keep this
        // card visually distinct across Weekly/Monthly/Yearly/Custom even
        // when the profit/loss color pair repeats.
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandDeep, AppColors.brandBlack],
              ),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 12)),
                BoxShadow(color: AppColors.brandLight.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(-5, -5)),
              ]),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30, top: -30,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                  ),
                ),
                Positioned(
                  right: -10, bottom: -18,
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Icon(_periodIcon, size: 108, color: Colors.white.withValues(alpha: 0.10)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 40, height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: Icon(_periodIcon, color: AppColors.white, size: 19),
                        ),
                        const SizedBox(width: 12),
                        const Text('Net Profit', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(profit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: AppColors.white),
                            const SizedBox(width: 4),
                            Text('${margin.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Text('₹${_fmtMoney.format(profit)}', style: const TextStyle(color: AppColors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                      const SizedBox(height: 4),
                      Text('Sales minus expenses for $_rangeLabel', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Sales / Expenses split ────────────────────────────────
        IntrinsicHeight(
          child: Row(children: [
            Expanded(
              child: _SplitStat(
                label: 'Sales', amount: totalSales, count: salesCount, countLabel: 'invoices',
                icon: Icons.point_of_sale_rounded, color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SplitStat(
                label: 'Expenses', amount: totalExpenses, count: expensesCount, countLabel: 'entries',
                icon: Icons.receipt_long_rounded, color: AppColors.positive,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 18),

        // ── Trend chart ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
              BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Sales vs Expenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const Spacer(),
                _LegendDot(color: AppColors.brand, label: 'Sales'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.positive, label: 'Expenses'),
              ]),
              const SizedBox(height: 18),
              _TrendChart(buckets: buckets, salesValues: salesByBucket, expenseValues: expensesByBucket),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Expense category breakdown ────────────────────────────
        if (topCategories.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Expense Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 16),
                ...topCategories.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final color = _reportPalette[i % _reportPalette.length];
                  final frac = totalExpenses > 0 ? cat.value / totalExpenses : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == topCategories.length - 1 ? 0 : 14),
                    child: _CategoryBar(label: cat.key, amount: cat.value, fraction: frac, color: color),
                  );
                }),
              ],
            ),
          ),
        if (topCategories.isNotEmpty) const SizedBox(height: 18),

        // ── Sales by status (donut) ───────────────────────────────
        if (statusEntries.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales by Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _DonutChart(
                      values: statusEntries.map((e) => e.value.toDouble()).toList(),
                      colors: List.generate(statusEntries.length, (i) => _reportPalette[i % _reportPalette.length]),
                      total: salesCount,
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statusEntries.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          final color = _reportPalette[i % _reportPalette.length];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i == statusEntries.length - 1 ? 0 : 10),
                            child: Row(children: [
                              Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.key, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                              Text('${s.value}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (statusEntries.isNotEmpty) const SizedBox(height: 18),

        // ── Sales by payment method ───────────────────────────────
        if (topMethods.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales by Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 16),
                ...topMethods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final color = _reportPalette[i % _reportPalette.length];
                  final frac = totalSales > 0 ? m.value / totalSales : 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == topMethods.length - 1 ? 0 : 14),
                    child: _CategoryBar(label: m.key, amount: m.value, fraction: frac, color: color),
                  );
                }),
              ],
            ),
          ),
        if (topMethods.isNotEmpty) const SizedBox(height: 18),

        // ── Profit margin gauge ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
              BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profit Margin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              _MarginGauge(margin: margin, rangeLabel: _rangeLabel),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Cumulative profit trend ────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
              BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cumulative Profit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text('Running total across the period', style: TextStyle(fontSize: 11.5, color: AppColors.textHint)),
              const SizedBox(height: 18),
              _AreaChart(buckets: buckets, values: cumulativeProfit),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Top customers ──────────────────────────────────────────
        if (topCustomers.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Customers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 16),
                ...topCustomers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final color = _reportPalette[i % _reportPalette.length];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == topCustomers.length - 1 ? 0 : 14),
                    child: _RankedRow(rank: i + 1, label: c.key, amount: c.value, color: color),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

List<Color> get _reportPalette => [AppColors.brand, AppColors.positive, AppColors.brandDeep, AppColors.brandLight, AppColors.brandBlack];

// ── Period selector ────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period period;
  final void Function(_Period) onSelect;
  const _PeriodSelector({required this.period, required this.onSelect});

  static const _labels = {
    _Period.weekly: 'Weekly',
    _Period.monthly: 'Monthly',
    _Period.yearly: 'Yearly',
    _Period.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Period.values.map((p) {
        final active = p == period;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: p == _Period.custom ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelect(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active ? const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]) : null,
                  color: active ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))])
                      : AppColors.shadows([
                          BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                          BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 4, offset: const Offset(-2, -2)),
                        ]),
                ),
                child: Text(
                  _labels[p]!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Split stat card (Sales / Expenses) ───────────────────────────────────────

class _SplitStat extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final String countLabel;
  final IconData icon;
  final Color color;
  const _SplitStat({
    required this.label,
    required this.amount,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final shadowDark = Color.lerp(color, AppColors.ink, 0.3)!;
    final shadowLight = Color.lerp(color, Colors.white, 0.4)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(color: shadowDark.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: shadowLight.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(-5, -5)),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('₹${fmt.format(amount)}', style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('$count $countLabel', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Trend chart (Sales vs Expenses paired bars) ──────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<_Bucket> buckets;
  final List<double> salesValues;
  final List<double> expenseValues;
  const _TrendChart({required this.buckets, required this.salesValues, required this.expenseValues});

  static const _chartHeight = 130.0;

  @override
  Widget build(BuildContext context) {
    final maxVal = [...salesValues, ...expenseValues].fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${buckets.length}-${salesValues.join()}-${expenseValues.join()}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return Column(
          children: [
            SizedBox(
              height: _chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(buckets.length, (i) {
                  final sH = ((salesValues[i] / safeMax) * _chartHeight * progress).clamp(salesValues[i] > 0 ? 3.0 : 0.0, _chartHeight);
                  final eH = ((expenseValues[i] / safeMax) * _chartHeight * progress).clamp(expenseValues[i] > 0 ? 3.0 : 0.0, _chartHeight);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              height: sH,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.brandLight, AppColors.brand]),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: eH,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.positive,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: buckets
                  .map((b) => Expanded(
                        child: Text(b.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

// ── Category breakdown bar ───────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final String label;
  final double amount;
  final double fraction;
  final Color color;
  const _CategoryBar({required this.label, required this.amount, required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
          Text('₹${fmt.format(amount)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LayoutBuilder(builder: (_, constraints) {
            return Stack(children: [
              Container(height: 6, width: constraints.maxWidth, color: AppColors.ink.withValues(alpha: 0.06)),
              Container(height: 6, width: constraints.maxWidth * fraction.clamp(0.0, 1.0), color: color),
            ]);
          }),
        ),
      ],
    );
  }
}

// ── Ranked row (Top Customers) ───────────────────────────────────────────

class _RankedRow extends StatelessWidget {
  final int rank;
  final String label;
  final double amount;
  final Color color;
  const _RankedRow({required this.rank, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Row(children: [
      Container(
        width: 26, height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.accentGradient(color)),
          shape: BoxShape.circle,
          boxShadow: AppColors.shadows([BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]),
        ),
        child: Text('$rank', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.white)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
      Text('₹${fmt.format(amount)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
    ]);
  }
}

// ── Profit margin gauge (semi-circle) ────────────────────────────────────

class _MarginGauge extends StatelessWidget {
  final double margin;
  final String rangeLabel;
  const _MarginGauge({required this.margin, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    // Clamp to [-50, 100]% for the sweep so a single bad period doesn't
    // pin the needle off the dial; the exact number is still shown below.
    final clamped = margin.clamp(-50.0, 100.0);
    final frac = (clamped + 50) / 150;
    final color = margin >= 0 ? AppColors.positive : AppColors.ink;

    return TweenAnimationBuilder<double>(
      key: ValueKey(margin),
      tween: Tween(begin: 0.0, end: frac),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, animatedFrac, _) {
        return SizedBox(
          height: 108,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: 220, height: 110,
                child: CustomPaint(painter: _GaugePainter(fraction: animatedFrac, color: color)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
                    Text(rangeLabel, style: TextStyle(fontSize: 10.5, color: AppColors.textHint)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  _GaugePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;

    final track = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi, false, track);

    final marker = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final midAngle = pi + pi / 2;
    final midOuter = center + Offset(cos(midAngle), sin(midAngle)) * (radius + strokeWidth / 2 + 3);
    final midInner = center + Offset(cos(midAngle), sin(midAngle)) * (radius - strokeWidth / 2 - 3);
    canvas.drawLine(midInner, midOuter, marker);

    if (fraction > 0) {
      final progress = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi * fraction, false, progress);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction || old.color != color;
}

// ── Cumulative area/line chart ───────────────────────────────────────────

class _AreaChart extends StatelessWidget {
  final List<_Bucket> buckets;
  final List<double> values;
  const _AreaChart({required this.buckets, required this.values});

  static const _height = 130.0;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold<double>(0, (a, b) => b.abs() > a ? b.abs() : a);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    final isNegative = values.isNotEmpty && values.last < 0;
    final color = isNegative ? AppColors.ink : AppColors.positive;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${buckets.length}-${values.join()}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return Column(
          children: [
            SizedBox(
              height: _height,
              width: double.infinity,
              child: CustomPaint(painter: _AreaPainter(values: values, maxVal: safeMax, progress: progress, color: color)),
            ),
            const SizedBox(height: 8),
            Row(
              children: buckets
                  .map((b) => Expanded(
                        child: Text(b.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;
  final double progress;
  final Color color;
  _AreaPainter({required this.values, required this.maxVal, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width;
    final zeroY = size.height / 2;

    Offset pointAt(int i) {
      final x = n > 1 ? i * stepX : size.width / 2;
      final y = zeroY - (values[i] / maxVal) * (zeroY - 6) * progress;
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < n; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(pointAt(n - 1).dx, zeroY)
      ..lineTo(pointAt(0).dx, zeroY)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), Paint()..color = AppColors.ink.withValues(alpha: 0.08)..strokeWidth = 1);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pointAt(i), 3, Paint()..color = color);
      canvas.drawCircle(pointAt(i), 1.4, Paint()..color = AppColors.white);
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.progress != progress || old.values != values || old.color != color;
}

// ── Donut chart ───────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final int total;
  const _DonutChart({required this.values, required this.colors, required this.total});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(values.join()),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return SizedBox(
          width: 92, height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(92, 92),
                painter: _DonutPainter(values: values, colors: colors, progress: progress),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1)),
                  Text('Total', style: TextStyle(fontSize: 9.5, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;
  _DonutPainter({required this.values, required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const gap = 0.045;
    double startAngle = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / total) * 2 * pi * progress - gap;
      if (sweep <= 0) {
        startAngle += (values[i] / total) * 2 * pi * progress;
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..strokeCap = StrokeCap.round,
      );
      startAngle += (values[i] / total) * 2 * pi * progress;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.values != values;
}

// ── Custom date range picker sheet ───────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class _DateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _DateRangeSheet({this.initialRange});

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  static final _fmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    final base = _start ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month, 1);
  }

  void _selectDay(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _quickSelect({int? lastDays, bool thisMonth = false, bool lastMonth = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      if (thisMonth) {
        _start = DateTime(now.year, now.month, 1);
        _end = today;
      } else if (lastMonth) {
        _start = DateTime(now.year, now.month - 1, 1);
        _end = DateTime(now.year, now.month, 0);
      } else {
        _start = today.subtract(Duration(days: (lastDays ?? 7) - 1));
        _end = today;
      }
      _visibleMonth = DateTime(_start!.year, _start!.month, 1);
    });
  }

  void _changeMonth(int delta) => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = _visibleMonth.weekday % 7;
    final canGoForward = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1).isBefore(DateTime(now.year, now.month + 1, 1));

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: Text('Select Date Range', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadows([
                        BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                        BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 3, offset: const Offset(-2, -2)),
                      ]),
                    ),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                _start == null
                    ? 'Pick a start date'
                    : _end == null
                        ? '${_fmt.format(_start!)} → Pick an end date'
                        : '${_fmt.format(_start!)} → ${_fmt.format(_end!)}',
                style: TextStyle(fontSize: 12.5, color: AppColors.textHint, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // ── Quick select chips ───────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _QuickChip(label: '7 Days', onTap: () => _quickSelect(lastDays: 7)),
                  const SizedBox(width: 8),
                  _QuickChip(label: '30 Days', onTap: () => _quickSelect(lastDays: 30)),
                  const SizedBox(width: 8),
                  _QuickChip(label: 'This Month', onTap: () => _quickSelect(thisMonth: true)),
                  const SizedBox(width: 8),
                  _QuickChip(label: 'Last Month', onTap: () => _quickSelect(lastMonth: true)),
                ]),
              ),
              const SizedBox(height: 18),

              // ── Calendar card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.shadows([
                    BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 8)),
                    BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 8, offset: const Offset(-3, -3)),
                  ]),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      _MonthNavButton(icon: Icons.chevron_left_rounded, onTap: () => _changeMonth(-1)),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ),
                      _MonthNavButton(icon: Icons.chevron_right_rounded, onTap: canGoForward ? () => _changeMonth(1) : null),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint)))))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leadingBlanks + daysInMonth,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                      itemBuilder: (_, i) {
                        if (i < leadingBlanks) return const SizedBox.shrink();
                        final day = DateTime(_visibleMonth.year, _visibleMonth.month, i - leadingBlanks + 1);
                        final isFuture = day.isAfter(DateTime(now.year, now.month, now.day));
                        final isStart = _start != null && _sameDay(day, _start!);
                        final isEnd = _end != null && _sameDay(day, _end!);
                        final inRange = _start != null && _end != null && day.isAfter(_start!) && day.isBefore(_end!);
                        final isToday = _sameDay(day, now);

                        return GestureDetector(
                          onTap: isFuture ? null : () => _selectDay(day),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: inRange ? AppColors.brand.withValues(alpha: 0.12) : null,
                                gradient: (isStart || isEnd) ? const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]) : null,
                                shape: BoxShape.circle,
                                border: isToday && !isStart && !isEnd ? Border.all(color: AppColors.brand, width: 1.3) : null,
                                boxShadow: (isStart || isEnd) ? AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]) : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: (isStart || isEnd) ? FontWeight.w800 : FontWeight.w500,
                                  color: (isStart || isEnd)
                                      ? AppColors.white
                                      : isFuture
                                          ? AppColors.textHint.withValues(alpha: 0.4)
                                          : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              BrixenButton(
                label: 'Apply Range',
                onPressed: (_start != null && _end != null) ? () => Navigator.pop(context, DateTimeRange(start: _start!, end: _end!)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.shadows([
            BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
            BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 4, offset: const Offset(-2, -2)),
          ]),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brand)),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthNavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadows([
            BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
            BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 3, offset: const Offset(-2, -2)),
          ]),
        ),
        child: Icon(icon, size: 18, color: disabled ? AppColors.textHint.withValues(alpha: 0.4) : AppColors.ink),
      ),
    );
  }
}

/// Mirrors the real report's period-selector / hero / split / chart-card
/// shape so nothing jumps in size once the summary call resolves.
class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(children: List.generate(4, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                child: const SkeletonBox(height: 40, radius: 20),
              ),
            );
          })),
          const SizedBox(height: 10),
          const SkeletonBox(width: 140, height: 12, radius: 4),
          const SizedBox(height: 18),

          // Profit hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const SkeletonBox(width: 40, height: 40, radius: 20),
                  const SizedBox(width: 12),
                  const SkeletonBox(width: 90, height: 14, radius: 4),
                  const Spacer(),
                  const SkeletonBox(width: 60, height: 24, radius: 12),
                ]),
                const SizedBox(height: 16),
                const SkeletonBox(width: 160, height: 32, radius: 6),
                const SizedBox(height: 6),
                const SkeletonBox(width: 200, height: 12, radius: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),

          IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _skeletonCard(height: 118)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonCard(height: 118)),
            ]),
          ),
          const SizedBox(height: 18),

          _skeletonCard(height: 220),
          const SizedBox(height: 18),
          _skeletonCard(height: 170),
        ],
      ),
    );
  }

  Widget _skeletonCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 130, height: 14, radius: 4),
          const Spacer(),
          const SkeletonBox(height: 10, radius: 4),
          const SizedBox(height: 8),
          const SkeletonBox(width: 140, height: 10, radius: 4),
        ],
      ),
    );
  }
}
