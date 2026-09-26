import '../entities/dashboard_summary.dart';
import '../entities/superadmin_dashboard.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();
  Future<SuperadminDashboard> getSuperadmin();
}
