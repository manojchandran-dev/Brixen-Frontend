import '../../../../../core/utils/money.dart';
import '../../../../customers/domain/entities/customer.dart';
import '../../../../employees/domain/entities/employee.dart';
import '../../../../expenses/domain/entities/expense.dart';
import '../../../../sales/domain/entities/sale.dart';

export '../../../../../core/utils/money.dart' show rupees;

// Today's numbers for the company dashboard, worked out from the module
// lists the app already loads (Sales, Expenses, Customers, Employees) — no
// dashboard-only API. Pure Dart so it's testable. Today's records are always
// within each list's first page (latest 200), so these are complete.

enum ActivityKind { sale, customer, employee, expense }

class DashActivity {
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime at;
  const DashActivity(this.kind, this.title, this.detail, this.at);
}

class TodayStats {
  final double sales;
  final int invoices;
  final double expenses;
  final List<DashActivity> activity;

  const TodayStats({
    required this.sales,
    required this.invoices,
    required this.expenses,
    required this.activity,
  });

  double get net => sales - expenses;

  factory TodayStats.compute({
    required DateTime now,
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Customer> customers,
    required List<Employee> employees,
    int activityLimit = 6,
  }) {
    bool today(DateTime t) =>
        t.year == now.year && t.month == now.month && t.day == now.day;

    final salesToday = sales.where((s) => today(s.billDate)).toList();
    final activity = <DashActivity>[
      for (final s in sales.where((s) => today(s.createdAt)))
        DashActivity(
          ActivityKind.sale,
          'Sale',
          '${s.customerName ?? 'Walk-in'} · ${rupees(s.totalAmount)}',
          s.createdAt,
        ),
      for (final c in customers.where((c) => today(c.createdAt)))
        DashActivity(
          ActivityKind.customer,
          'New customer',
          c.name,
          c.createdAt,
        ),
      for (final e in employees.where((e) => today(e.createdAt)))
        DashActivity(
          ActivityKind.employee,
          'New employee',
          e.fullName,
          e.createdAt,
        ),
      for (final e in expenses.where((e) => today(e.createdAt)))
        DashActivity(
          ActivityKind.expense,
          'Expense',
          '${e.title} · ${rupees(e.amount)}',
          e.createdAt,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return TodayStats(
      sales: salesToday.fold(0, (a, s) => a + s.totalAmount),
      invoices: salesToday.length,
      expenses: expenses
          .where((e) => today(e.expenseDate))
          .fold(0, (a, e) => a + e.amount),
      activity: activity.take(activityLimit).toList(),
    );
  }
}
