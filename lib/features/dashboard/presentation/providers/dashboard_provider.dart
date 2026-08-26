import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_summary.dart';

final dashboardSummaryProvider = AsyncNotifierProvider<DashboardSummaryNotifier, DashboardSummary>(
  DashboardSummaryNotifier.new,
);

class DashboardSummaryNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    return ref.read(dashboardRemoteDatasourceProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRemoteDatasourceProvider).getSummary());
  }
}
