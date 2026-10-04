import 'package:brixen/features/customers/domain/entities/customer.dart';
import 'package:brixen/features/customers/presentation/providers/customers_provider.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/employees/presentation/providers/employees_provider.dart';
import 'package:brixen/features/expenses/domain/entities/expense.dart';
import 'package:brixen/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:brixen/features/products/domain/entities/product.dart';
import 'package:brixen/features/products/presentation/providers/products_provider.dart';
import 'package:brixen/features/reports/presentation/company/company_report_pages.dart';
import 'package:brixen/features/reports/presentation/company/company_reports_data.dart';
import 'package:brixen/features/reports/presentation/company/company_reports_hub.dart';
import 'package:brixen/features/reports/presentation/superadmin/superadmin_reports_data.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:brixen/features/sales/presentation/providers/sales_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.now();
DateTime _ago(int d) => _now.subtract(Duration(days: d));

Sale _sale(
  String id,
  String? customer,
  double price,
  int qty,
  DateTime at, {
  String product = 'p1',
  String status = 'paid',
}) => Sale(
  id: id,
  customerId: customer,
  customerName: customer == null ? null : 'Ravi',
  billDate: at,
  subtotal: price * qty,
  taxAmount: 0,
  totalAmount: price * qty,
  paymentStatus: status,
  paymentType: 'UPI',
  items: [
    SaleItem(
      productId: product,
      productName: 'Item $product',
      priceType: 'retail',
      price: price,
      quantity: qty,
    ),
  ],
  createdAt: at,
);

final _sales = [
  _sale('s1', 'c1', 500, 2, _now),
  _sale('s2', 'c1', 300, 1, _ago(2), product: 'p2', status: 'pending'),
  _sale('s3', null, 200, 3, _ago(10)),
  _sale('s4', 'c2', 1000, 1, _ago(200)),
];
final _products = [
  Product(
    id: 'p1',
    productCode: 'P1',
    productName: 'Cotton Shirt',
    category: 'Shirts',
    gender: 'Men',
    costPrice: 1,
    retailPrice: 500,
    wholesalePrice: 400,
    createdAt: _ago(300),
  ),
  Product(
    id: 'p2',
    productCode: 'P2',
    productName: 'Kids Frock',
    category: 'Kids',
    gender: 'Kids',
    costPrice: 1,
    retailPrice: 300,
    wholesalePrice: 250,
    status: 'Inactive',
    createdAt: _ago(300),
  ),
];
final _customers = [
  Customer(id: 'c1', name: 'Ravi', shopName: 'Ravi Stores', createdAt: _ago(1)),
  Customer(id: 'c2', name: 'Meena', phone: '98400', createdAt: _ago(100)),
];
final _expenses = [
  Expense(
    id: 'e1',
    categoryId: 'k1',
    category: 'Rent',
    title: 'Shop rent',
    amount: 5000,
    expenseDate: _ago(1),
    createdAt: _ago(1),
  ),
  Expense(
    id: 'e2',
    categoryId: 'k2',
    category: 'Travel',
    title: 'Auto',
    amount: 200,
    expenseDate: _ago(3),
    createdAt: _ago(3),
  ),
];
final _employees = [
  Employee(
    id: 'm1',
    companyId: '2',
    employeeCode: 'E1',
    firstName: 'Priya',
    department: 'Stitching',
    createdAt: _ago(5),
  ),
  Employee(
    id: 'm2',
    companyId: '2',
    employeeCode: 'E2',
    firstName: 'Arun',
    department: 'Sales',
    status: 'Inactive',
    createdAt: _ago(90),
  ),
];

class _Sales extends SalesNotifier {
  @override
  Future<List<Sale>> build() async => _sales;
}

class _Products extends ProductsNotifier {
  @override
  Future<List<Product>> build() async => _products;
}

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => _customers;
}

class _Expenses extends ExpensesNotifier {
  @override
  Future<List<Expense>> build() async => _expenses;
}

class _Employees extends EmployeesNotifier {
  @override
  Future<List<Employee>> build() async => _employees;
}

final _overrides = [
  salesProvider.overrideWith(_Sales.new),
  productsProvider.overrideWith(_Products.new),
  customersProvider.overrideWith(_Customers.new),
  expensesProvider.overrideWith(_Expenses.new),
  employeesProvider.overrideWith(_Employees.new),
];

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  const week = ReportPeriod(ReportRange.week);
  const month = ReportPeriod(ReportRange.month);
  const all = ReportPeriod(ReportRange.all);

  test('periodBounds / inPeriod: week, month, custom, all', () {
    expect(inPeriod(_ago(6), week, _now), isTrue);
    expect(inPeriod(_ago(8), week, _now), isFalse);
    expect(inPeriod(_ago(29), month, _now), isTrue);
    expect(inPeriod(_ago(400), all, _now), isTrue);
    final custom = ReportPeriod(
      ReportRange.custom,
      DateTimeRange(start: _ago(3), end: _ago(1)),
    );
    expect(inPeriod(_ago(2), custom, _now), isTrue);
    expect(inPeriod(_now, custom, _now), isFalse);
  });

  test('amountBuckets: bar counts per range and totals add up', () {
    final pts = [for (final s in _sales) (s.billDate, s.totalAmount)];
    final w = amountBuckets(
      pts.where((p) => inPeriod(p.$1, week, _now)),
      week,
      _now,
    );
    expect(w, hasLength(7));
    expect(w.fold<int>(0, (a, b) => a + b.count), 1300);
    expect(amountBuckets(pts, month, _now), hasLength(5));
    final a = amountBuckets(pts, all, _now);
    expect(a.length, inInclusiveRange(1, 12));
    expect(a.fold<int>(0, (x, b) => x + b.count), 2900);
  });

  test('Tallies: by product, by category, by customer (walk-ins together)', () {
    final p = salesByProduct(_sales, _products);
    expect(p.first.label, 'Cotton Shirt');
    expect(p.first.quantity, 6);
    expect(p.first.amount, 1600 + 1000);
    expect(
      salesByCategory(_sales, _products).map((t) => t.label),
      containsAll(['Shirts', 'Kids']),
    );
    final c = purchasesByCustomer(_sales, _customers);
    expect(c.firstWhere((t) => t.label == 'Ravi').count, 2);
    expect(c.any((t) => t.label == 'Walk-in'), isTrue);
    expect(expensesByCategory(_expenses).first.label, 'Rent');
  });

  test('Profit & loss: net sales, COGS, gross/net profit, uncosted lines', () {
    // Week: s1 (2×500, Cotton Shirt cost 1) and s2 (1×300, Kids Frock cost 1).
    final s = [
      for (final x in _sales)
        if (inPeriod(x.billDate, week, _now)) x,
    ];
    final e = [
      for (final x in _expenses)
        if (inPeriod(x.expenseDate, week, _now)) x,
    ];
    final pl = ProfitLoss.of(s, e, _products);
    expect(pl.grossSales, 1300);
    expect(pl.tax, 0);
    expect(pl.netSales, 1300);
    expect(pl.cogs, 3); // 2×1 + 1×1
    expect(pl.grossProfit, 1297);
    expect(pl.expenses, 5200);
    expect(pl.netProfit, 1297 - 5200);
    expect(pl.uncostedLines, 0);
    expect(pl.margin(pl.grossProfit)!.round(), 100);
    // A product with no cost price counts as zero cost, and is flagged.
    final noCost = ProfitLoss.of(s, e, const []);
    expect(noCost.cogs, 0);
    expect(noCost.uncostedLines, 2);
    final rows = profitByPeriod(s, e, _products, week, _now);
    expect(rows, hasLength(7));
    expect(rows.fold<int>(0, (a, r) => a + r.sales), 1300);
    expect(rows.fold<int>(0, (a, r) => a + r.expenses), 5200);
  });

  testWidgets('Reports: five tabs, switch by tap or swipe, date shared', (
    tester,
  ) async {
    await _pump(tester, const Scaffold(body: CompanyReportsHub()));
    for (final tab in [
      'Sales',
      'Expenses',
      'Customers',
      'Products',
      'Employees',
    ]) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    expect(find.text('Sales by date'), findsOneWidget); // first tab

    await tester.tap(find.text('Week'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Expenses').first);
    await tester.pumpAndSettle();
    expect(find.text('Expenses by date'), findsOneWidget);
    expect(
      find.text('Last 7 days'),
      findsNothing,
    ); // caption isn't shown in tabs
    // The Week choice carried over: its chip is still the selected one.
    // (Neighbouring tabs stay built, so check every Week chip.)
    for (final w in tester.widgetList<Text>(find.text('Week'))) {
      expect(w.style?.fontWeight, FontWeight.w800);
    }

    await tester.drag(find.byType(TabBarView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Profit & loss statement'), findsOneWidget); // P&L tab
    expect(tester.takeException(), isNull);
  });

  final reports = <String, Widget>{
    'Sales': const CompanySalesReport(),
    'Expense': const CompanyExpenseReport(),
    'Customer': const CompanyCustomerReport(),
    'Product': const CompanyProductReport(),
    'Employee': const CompanyEmployeeReport(),
    'Profit & loss': const CompanyProfitLossReport(),
  };
  reports.forEach((name, page) {
    testWidgets('$name report renders every range at phone size', (
      tester,
    ) async {
      await _pump(tester, Scaffold(body: page));
      for (final r in ['Week', 'Month', 'All']) {
        await tester.tap(find.text(r));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$name · $r');
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$name scrolled');
    });
  });
}
