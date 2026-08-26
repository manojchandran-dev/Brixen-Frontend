class WeeklySignup {
  final DateTime weekStart;
  final int count;
  const WeeklySignup({required this.weekStart, required this.count});
}

class PlanCount {
  final String plan;
  final int count;
  const PlanCount({required this.plan, required this.count});
}

class RecentSaleSummary {
  final String id;
  final String customerName;
  final DateTime date;
  final double amount;
  final String status;
  const RecentSaleSummary({
    required this.id,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class DashboardSummary {
  final int totalCompanies;
  final int activeCompanies;
  final int totalEmployees;
  final List<WeeklySignup> weeklySignups;
  final List<PlanCount> subscriptionPlans;
  final List<RecentSaleSummary> recentSales;

  const DashboardSummary({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.totalEmployees,
    required this.weeklySignups,
    required this.subscriptionPlans,
    required this.recentSales,
  });
}
