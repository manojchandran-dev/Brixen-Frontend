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

class RecentExpenseSummary {
  final String id;
  final String title;
  final DateTime date;
  final double amount;
  const RecentExpenseSummary({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
  });
}

/// `GET /dashboard/summary` branches server-side on whether `company_id`
/// was sent (auto-attached by `CompanyScopeInterceptor` for any
/// non-superAdmin session): superAdmin gets the platform-wide fields
/// (companies/weeklySignups/subscriptionPlans), companyAdmin gets the
/// company-scoped ones (totalCustomers/totalProducts/recentExpenses) —
/// each role's dashboard body only ever reads the fields meant for it.
class DashboardSummary {
  final int totalCompanies;
  final int activeCompanies;
  final int totalEmployees;
  final int totalCustomers;
  final int totalProducts;
  final List<WeeklySignup> weeklySignups;
  final List<PlanCount> subscriptionPlans;
  final List<RecentSaleSummary> recentSales;
  final List<RecentExpenseSummary> recentExpenses;

  const DashboardSummary({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.totalEmployees,
    this.totalCustomers = 0,
    this.totalProducts = 0,
    required this.weeklySignups,
    required this.subscriptionPlans,
    required this.recentSales,
    this.recentExpenses = const [],
  });
}
