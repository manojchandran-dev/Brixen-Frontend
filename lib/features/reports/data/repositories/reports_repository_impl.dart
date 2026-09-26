import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reports_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.read(reportsRemoteDatasourceProvider));
});

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDatasource _ds;
  const ReportsRepositoryImpl(this._ds);

  @override
  Future<ReportsSummary> getSummary({
    required String period,
    DateTime? from,
    DateTime? to,
    int topCategoriesLimit = 5,
    int topCustomersLimit = 5,
  }) => _ds.getSummary(
    period: period,
    from: from,
    to: to,
    topCategoriesLimit: topCategoriesLimit,
    topCustomersLimit: topCustomersLimit,
  );
}
