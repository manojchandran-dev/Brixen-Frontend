class DailyPoint {
  final DateTime date;
  final double sales;
  final double expenses;
  const DailyPoint({
    required this.date,
    required this.sales,
    required this.expenses,
  });
}

class CumulativePoint {
  final DateTime date;
  final double value;
  const CumulativePoint({required this.date, required this.value});
}

class NamedAmount {
  final String label;
  final double amount;
  const NamedAmount({required this.label, required this.amount});
}

class StatusCount {
  final String status;
  final int count;
  const StatusCount({required this.status, required this.count});
}

class ReportsSummary {
  final String period;
  final double salesTotal;
  final int salesCount;
  final double expensesTotal;
  final int expensesCount;
  final double netProfit;
  final double profitMarginPct;
  final List<DailyPoint> salesVsExpenses;
  final List<CumulativePoint> cumulativeProfit;
  final List<NamedAmount> topSellingCategories;
  final List<NamedAmount> topExpenseCategories;
  final List<StatusCount> salesByStatus;
  final List<NamedAmount> salesByPaymentMethod;
  final List<NamedAmount> topCustomers;

  const ReportsSummary({
    required this.period,
    required this.salesTotal,
    required this.salesCount,
    required this.expensesTotal,
    required this.expensesCount,
    required this.netProfit,
    required this.profitMarginPct,
    required this.salesVsExpenses,
    required this.cumulativeProfit,
    required this.topSellingCategories,
    required this.topExpenseCategories,
    required this.salesByStatus,
    required this.salesByPaymentMethod,
    required this.topCustomers,
  });
}
