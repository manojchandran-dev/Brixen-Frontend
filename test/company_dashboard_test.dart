import 'package:brixen/features/customers/domain/entities/customer.dart';
import 'package:brixen/features/customers/presentation/providers/customers_provider.dart';
import 'package:brixen/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:brixen/features/dashboard/presentation/pages/company_admin/company_admin_dashboard_page.dart';
import 'package:brixen/features/dashboard/presentation/pages/company_admin/company_dashboard_stats.dart';
import 'package:brixen/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/employees/presentation/providers/employees_provider.dart';
import 'package:brixen/features/expenses/domain/entities/expense.dart';
import 'package:brixen/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:brixen/features/notifications/presentation/providers/inbox_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/presentation/providers/products_provider.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:brixen/features/sales/presentation/providers/sales_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.now();
DateTime _ago(int days, [int hours = 0]) =>
    _now.subtract(Duration(days: days, hours: hours));

Sale _sale(String id, double total, DateTime at, {String status = 'paid'}) =>
    Sale(
      id: id,
      billDate: at,
      subtotal: total,
      taxAmount: 0,
      totalAmount: total,
      paymentStatus: status,
      customerName: 'Ravi',
      items: [
        SaleItem(
          productId: 'p1',
          productName: 'Cotton Shirt',
          priceType: 'retail',
          price: total / 2,
          quantity: 2,
        ),
      ],
      createdAt: at,
    );

final _sales = [
  _sale('s1', 1000, _now),
  _sale('s2', 500, _now, status: 'pending'),
  _sale('s3', 1000, _ago(1)), // yesterday
  _sale('s4', 800, _ago(3)),
];
final _expenses = [
  Expense(
    id: 'e1',
    categoryId: 'c1',
    category: 'Rent',
    title: 'Shop rent',
    amount: 300,
    expenseDate: _now,
    createdAt: _now,
  ),
  Expense(
    id: 'e2',
    categoryId: 'c2',
    category: 'Travel',
    title: 'Auto',
    amount: 100,
    expenseDate: _now,
    createdAt: _now,
  ),
];
final _customers = [
  Customer(id: 'c1', name: 'Ravi', shopName: 'Ravi Stores', createdAt: _now),
  Customer(id: 'c2', name: 'Meena', createdAt: _ago(40)),
];
final _products = [
  Product(
    id: 'p1',
    productCode: 'P1',
    productName: 'Cotton Shirt',
    category: 'Shirts',
    gender: 'Men',
    costPrice: 200,
    retailPrice: 500,
    wholesalePrice: 400,
    createdAt: _ago(10),
  ),
];
final _employees = [
  Employee(
    id: 'm1',
    companyId: '2',
    employeeCode: 'E1',
    firstName: 'Priya',
    createdAt: _now,
  ),
];

void main() {
  test("Today: sales, invoices, expenses, net and today-only activity", () {
    final t = TodayStats.compute(
      now: _now,
      sales: _sales,
      expenses: _expenses,
      customers: _customers,
      employees: _employees,
    );
    expect(t.sales, 1500); // s1 + s2; yesterday and 3-days-ago left out
    expect(t.invoices, 2);
    expect(t.expenses, 400);
    expect(t.net, 1100);
    // 2 sales + 1 customer (Meena is old) + 1 employee + 2 expenses.
    expect(t.activity, hasLength(6));
    expect(t.activity.map((a) => a.kind).toSet(), ActivityKind.values.toSet());
  });

  test("rupees: compact above a lakh, signed when negative", () {
    expect(rupees(12450), "₹12,450");
    expect(rupees(125000), "₹1.3L");
    expect(rupees(34000000), "₹3.4Cr");
    expect(rupees(-500), "−₹500");
  });

  testWidgets("Dashboard renders every section at phone size", (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith(_Summary.new),
          salesProvider.overrideWith(_Sales.new),
          expensesProvider.overrideWith(_Expenses.new),
          customersProvider.overrideWith(_Customers.new),
          productsProvider.overrideWith(_Products.new),
          employeesProvider.overrideWith(_Employees.new),
          inboxProvider.overrideWith((ref) async => const Inbox([], 0)),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(
              view: true,
              create: true,
              edit: true,
              delete: true,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CompanyAdminDashboardPage(onIconTap: (_) {})),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text("Business summary"), findsOneWidget);
    expect(find.text("₹1,500"), findsOneWidget); // today's sales card
    expect(find.text("2 invoices"), findsOneWidget);

    for (final title in [
      "Quick actions",
      "Today's activity",
      "Inventory alert",
      "Today's status",
    ]) {
      await tester.scrollUntilVisible(find.text(title), 300);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: title);
    }
    expect(find.text("₹1,100"), findsOneWidget); // net
    // Report-style sections are gone.
    expect(find.text("Top selling products"), findsNothing);
    expect(find.text("Sales overview"), findsNothing);
  });
}

class _Summary extends DashboardSummaryNotifier {
  @override
  Future<DashboardSummary> build() async => const DashboardSummary(
    totalCompanies: 0,
    activeCompanies: 0,
    totalEmployees: 1,
    totalCustomers: 2,
    totalProducts: 1,
    weeklySignups: [],
    subscriptionPlans: [],
    recentSales: [],
  );
}

class _Sales extends SalesNotifier {
  @override
  Future<List<Sale>> build() async => _sales;
}

class _Expenses extends ExpensesNotifier {
  @override
  Future<List<Expense>> build() async => _expenses;
}

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => _customers;
}

class _Products extends ProductsNotifier {
  @override
  Future<List<Product>> build() async => _products;
}

class _Employees extends EmployeesNotifier {
  @override
  Future<List<Employee>> build() async => _employees;
}
