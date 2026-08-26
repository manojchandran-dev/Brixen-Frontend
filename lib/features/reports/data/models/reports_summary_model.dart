import '../../domain/entities/reports_summary.dart';

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
DateTime _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

/// Tries each key in order and returns the first present value — used where
/// the exact field name for a breakdown label wasn't pinned down precisely
/// (e.g. `method` vs `payment_method`), so a minor backend naming difference
/// doesn't silently blank a whole card.
String _pick(Map json, List<String> keys, String fallback) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

class ReportsSummaryModel extends ReportsSummary {
  const ReportsSummaryModel({
    required super.period,
    required super.salesTotal,
    required super.salesCount,
    required super.expensesTotal,
    required super.expensesCount,
    required super.netProfit,
    required super.profitMarginPct,
    required super.salesVsExpenses,
    required super.cumulativeProfit,
    required super.topExpenseCategories,
    required super.salesByStatus,
    required super.salesByPaymentMethod,
    required super.topCustomers,
  });

  factory ReportsSummaryModel.fromJson(Map<String, dynamic> json) {
    final salesVsExpenses = (json['sales_vs_expenses'] as List?) ?? const [];
    final cumulativeProfit = (json['cumulative_profit'] as List?) ?? const [];
    final topExpenseCategories = (json['top_expense_categories'] as List?) ?? const [];
    final salesByStatus = (json['sales_by_status'] as List?) ?? const [];
    final salesByPaymentMethod = (json['sales_by_payment_method'] as List?) ?? const [];
    final topCustomers = (json['top_customers'] as List?) ?? const [];

    return ReportsSummaryModel(
      period: (json['period'] ?? '').toString(),
      salesTotal: _num(json['sales_total']),
      salesCount: _int(json['sales_count']),
      expensesTotal: _num(json['expenses_total']),
      expensesCount: _int(json['expenses_count']),
      netProfit: _num(json['net_profit']),
      profitMarginPct: _num(json['profit_margin_pct']),
      salesVsExpenses: salesVsExpenses
          .map((e) => DailyPoint(
                date: _date((e as Map)['date']),
                sales: _num(e['sales']),
                expenses: _num(e['expenses']),
              ))
          .toList(),
      cumulativeProfit: cumulativeProfit
          .map((e) => CumulativePoint(
                date: _date((e as Map)['date']),
                value: _num(e['value'] ?? e['profit']),
              ))
          .toList(),
      topExpenseCategories: topExpenseCategories
          .map((e) => NamedAmount(
                label: _pick(e as Map, ['category'], 'Uncategorised'),
                amount: _num(e['amount']),
              ))
          .toList(),
      salesByStatus: salesByStatus
          .map((e) => StatusCount(
                status: _pick(e as Map, ['status'], 'Unknown'),
                count: _int(e['count']),
              ))
          .toList(),
      salesByPaymentMethod: salesByPaymentMethod
          .map((e) => NamedAmount(
                label: _pick(e as Map, ['method', 'payment_method'], 'Unspecified'),
                amount: _num(e['amount']),
              ))
          .toList(),
      topCustomers: topCustomers
          .map((e) => NamedAmount(
                label: _pick(e as Map, ['name', 'customer_name'], 'Walk-in'),
                amount: _num(e['amount']),
              ))
          .toList(),
    );
  }
}
