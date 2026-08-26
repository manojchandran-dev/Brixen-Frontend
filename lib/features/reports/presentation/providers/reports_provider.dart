import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../domain/entities/reports_summary.dart';

class ReportsQuery extends Equatable {
  final String period;
  final DateTime from;
  final DateTime to;
  const ReportsQuery({required this.period, required this.from, required this.to});

  @override
  List<Object?> get props => [period, from, to];
}

final reportsSummaryProvider =
    AsyncNotifierProvider.family<ReportsSummaryNotifier, ReportsSummary, ReportsQuery>(
  ReportsSummaryNotifier.new,
);

class ReportsSummaryNotifier extends FamilyAsyncNotifier<ReportsSummary, ReportsQuery> {
  @override
  Future<ReportsSummary> build(ReportsQuery arg) async {
    return ref.read(reportsRemoteDatasourceProvider).getSummary(
          period: arg.period,
          from: arg.from,
          to: arg.to,
        );
  }
}
