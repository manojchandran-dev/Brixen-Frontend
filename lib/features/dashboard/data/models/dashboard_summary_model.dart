import '../../domain/entities/dashboard_summary.dart';

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
DateTime _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.totalCompanies,
    required super.activeCompanies,
    required super.totalEmployees,
    required super.weeklySignups,
    required super.subscriptionPlans,
    required super.recentSales,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final companies = json['companies'] as Map<String, dynamic>? ?? const {};
    final employees = json['employees'] as Map<String, dynamic>? ?? const {};
    final weekly = (json['weekly_signups'] as List?) ?? const [];
    final plans = (json['subscription_plans'] as List?) ?? const [];
    final recent = (json['recent_sales'] as List?) ?? const [];

    return DashboardSummaryModel(
      totalCompanies: _int(companies['total']),
      activeCompanies: _int(companies['active']),
      totalEmployees: _int(employees['total']),
      weeklySignups: weekly
          .map((e) => WeeklySignup(
                weekStart: _date((e as Map)['week_start']),
                count: _int(e['count']),
              ))
          .toList(),
      subscriptionPlans: plans
          .map((e) => PlanCount(
                plan: ((e as Map)['plan'] ?? 'Unassigned').toString(),
                count: _int(e['count']),
              ))
          .toList(),
      recentSales: recent
          .map((e) => RecentSaleSummary(
                id: (e as Map)['id'].toString(),
                customerName: (e['customer_name'] ?? 'Walk-in').toString(),
                date: _date(e['date']),
                amount: _num(e['amount']),
                status: (e['status'] ?? 'Pending').toString(),
              ))
          .toList(),
    );
  }
}
