import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../navigation/presentation/providers/nav_modules_provider.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/superadmin_dashboard.dart';

final dashboardSummaryProvider = AsyncNotifierProvider<DashboardSummaryNotifier, DashboardSummary>(
  DashboardSummaryNotifier.new,
);

class DashboardSummaryNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    // Same fix as navModulesProvider: without depending on auth state, this
    // stays cached across a logout/login in the same app session — a
    // superAdmin's platform-wide summary would keep showing after a
    // companyAdmin logs in right after, instead of refetching the
    // company-scoped branch.
    ref.watch(authStateProvider);
    return ref.read(dashboardRepositoryProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).getSummary());
  }
}

/// Superadmin dashboard — one call (`GET /dashboard/superadmin`) instead of
/// the summary plus separate ticket/push/company/health requests.
final superadminDashboardProvider = FutureProvider<SuperadminDashboard>((ref) {
  ref.watch(authStateProvider); // refetch after switching accounts
  return ref.read(dashboardRepositoryProvider).getSuperadmin();
});
