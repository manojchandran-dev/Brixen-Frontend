import '../entities/reports_summary.dart';

abstract class ReportsRepository {
  Future<ReportsSummary> getSummary({
    required String period,
    DateTime? from,
    DateTime? to,
    int topCategoriesLimit = 5,
    int topCustomersLimit = 5,
  });
}
