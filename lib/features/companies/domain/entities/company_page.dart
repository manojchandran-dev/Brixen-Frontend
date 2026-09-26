import 'company.dart';

/// One `GET /companies` result: the rows, the server's total for the
/// current search + filters, and the counts for each filter chip, e.g.
/// `{'status': {'ACTIVE': 1, 'INACTIVE': 2}, 'subscription_plan': {...}}`.
class CompanyPage {
  final List<Company> items;
  final int total;
  final Map<String, Map<String, int>> counts;
  const CompanyPage({
    required this.items,
    required this.total,
    this.counts = const {},
  });
}
