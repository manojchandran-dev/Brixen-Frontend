import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/superadmin_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.read(dashboardRemoteDatasourceProvider));
});

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource _ds;
  const DashboardRepositoryImpl(this._ds);

  @override
  Future<DashboardSummary> getSummary() => _ds.getSummary();

  @override
  Future<SuperadminDashboard> getSuperadmin() => _ds.getSuperadmin();
}
