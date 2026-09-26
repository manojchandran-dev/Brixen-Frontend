import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// The date filter choices on every superadmin report.
enum ReportRange { week, month, custom, all }

/// The selected period: a [range], plus the picked dates for [ReportRange.custom].
class ReportPeriod {
  final ReportRange range;
  final DateTimeRange? custom;
  const ReportPeriod(this.range, [this.custom]);

  static final _day = DateFormat('d MMM');
  static final _api = DateFormat('yyyy-MM-dd');

  /// Chip / tile text: "Week", "Month", "12 Sep – 20 Sep", "All".
  String get label => switch (range) {
    ReportRange.week => 'Week',
    ReportRange.month => 'Month',
    ReportRange.custom =>
      custom == null
          ? 'Custom'
          : '${_day.format(custom!.start)} – ${_day.format(custom!.end)}',
    ReportRange.all => 'All',
  };

  /// Chart caption: "Last 7 days", "12 Sep – 20 Sep 2026", ...
  String get caption => switch (range) {
    ReportRange.week => 'Last 7 days',
    ReportRange.month => 'Last 30 days',
    ReportRange.custom =>
      custom == null
          ? 'Custom range'
          : '${_day.format(custom!.start)} – ${DateFormat('d MMM yyyy').format(custom!.end)}',
    ReportRange.all => 'All time',
  };

  /// `range` (+ `from`/`to` for custom) as the report endpoints expect.
  Map<String, String> get query => {
    'range': range.name,
    if (range == ReportRange.custom && custom != null) ...{
      'from': _api.format(custom!.start),
      'to': _api.format(custom!.end),
    },
  };

  // Value equality: the period is part of the report provider's family key.
  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.range == range && other.custom == custom;

  @override
  int get hashCode => Object.hash(range, custom);
}

/// One bar of a report trend chart.
class TrendBucket {
  final String label;
  final int count;
  const TrendBucket(this.label, this.count);
}

/// `GET /reports/superadmin/{tab}` for a period — the server counts and
/// buckets everything; the raw `data` map is read by the report pages.
/// Tab: company | users | notifications | support | chatbot | activity.
final superadminReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, (String, ReportPeriod)>((ref, key) async {
      final (tab, period) = key;
      try {
        final resp = await ref
            .read(dioProvider)
            .get(
              '${ApiEndpoints.superadminReports}/$tab',
              queryParameters: period.query,
            );
        final data = resp.data['data'] ?? resp.data;
        return data is Map ? Map<String, dynamic>.from(data) : const {};
      } on DioException catch (e) {
        throw mapDioError(e);
      }
    });

// ── Tolerant readers: a missing or odd field reads as 0 / empty ─────────────

Map<String, dynamic> obj(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

int n(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

List<Map<String, dynamic>> rows(Object? v) =>
    v is List ? [for (final r in v) obj(r)] : const [];

DateTime? at(Object? v) => DateTime.tryParse('$v')?.toLocal();

String str(Object? v) => v == null ? '' : '$v';

/// The `trend` list as chart bars (the server sends them oldest first).
List<TrendBucket> trend(Object? v) => [
  for (final b in rows(v)) TrendBucket(str(b['label']), n(b['count'])),
];
