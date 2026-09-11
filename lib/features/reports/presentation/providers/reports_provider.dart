import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../navigation/presentation/providers/nav_modules_provider.dart';
import '../../data/repositories/reports_repository_impl.dart';
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
    // Same fix as navModulesProvider/dashboardSummaryProvider: the cache
    // key here (period/from/to) carries no session identity, so without
    // this a company's report for, say, "weekly" would keep showing after
    // a different company (or role) logs in and requests the exact same
    // period in the same app session, instead of refetching for the new
    // company_id.
    ref.watch(authStateProvider);
    return ref.read(reportsRepositoryProvider).getSummary(
          period: arg.period,
          from: arg.from,
          to: arg.to,
        );
  }
}
