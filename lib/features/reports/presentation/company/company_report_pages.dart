import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../sales/domain/entities/sale.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../superadmin/report_kit.dart';
import 'company_report_kit.dart';
import 'company_reports_data.dart';

final _day = DateFormat('d MMM yyyy');
String _money(int v) => rupees(v.toDouble());

const _palette = [
  AppColors.brand,
  AppColors.positive,
  AppColors.brandDeep,
  AppColors.brandLight,
  AppColors.brandBlack,
];

/// Donut of the top 5 [tallies] by amount (+ "Others").
Widget _amountDonut(List<Tally> tallies) {
  final top = tallies.take(5).toList();
  final rest = tallies.skip(5).fold<double>(0, (a, t) => a + t.amount);
  return ReportBreakdown([
    for (final (i, t) in top.indexed)
      BreakdownItem(t.label, t.amount.round(), _palette[i % _palette.length]),
    if (rest > 0) BreakdownItem('Others', rest.round(), AppColors.textHint),
  ], valueLabel: _money);
}

/// Rank badge + title/subtitle + trailing value — a detail-list row.
class _RankRow extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String value;
  final String? valueSub;
  const _RankRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueSub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.positive : AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1 ? Colors.white : AppColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (valueSub != null)
                Text(
                  valueSub!,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── 1. Sales report ───────────────────────────────────────────────────────

class CompanySalesReport extends ConsumerWidget {
  const CompanySalesReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final products = ref.watch(productsProvider);
    return CompanyReportScreen(
      loading: sales.isLoading && !sales.hasValue,
      error: sales.hasValue ? null : sales.error,
      onRetry: () => ref.invalidate(salesProvider),
      body: (period) {
        final now = DateTime.now();
        final list = [
          for (final s in sales.valueOrNull ?? const <Sale>[])
            if (inPeriod(s.billDate, period, now)) s,
        ];
        final prods = products.valueOrNull ?? const <Product>[];
        final total = list.fold<double>(0, (a, s) => a + s.totalAmount);
        final unpaid = list.where((s) => s.balance > 0);
        final byProduct = salesByProduct(list, prods);
        return [
          ReportSummary([
            ReportStat(
              Icons.point_of_sale_rounded,
              'Total sales',
              rupees(total),
              AppColors.positive,
            ),
            ReportStat(
              Icons.receipt_rounded,
              'Invoices',
              '${list.length}',
              AppColors.brand,
            ),
            ReportStat(
              Icons.functions_rounded,
              'Avg invoice',
              rupees(list.isEmpty ? 0 : total / list.length),
              AppColors.brandDeep,
            ),
            ReportStat(
              Icons.pending_actions_rounded,
              'Unpaid · ${unpaid.length}',
              rupees(unpaid.fold<double>(0, (a, s) => a + s.balance)),
              AppColors.brandBlack,
            ),
          ]),
          ReportCard(
            title: 'Sales by date',
            caption: 'Invoice value',
            child: ReportTrendChart(
              buckets: amountBuckets(
                [for (final s in list) (s.billDate, s.totalAmount)],
                period,
                now,
              ),
              valueLabel: _money,
            ),
          ),
          ReportCard(
            title: 'Sales by category',
            caption: 'Line-item revenue',
            child: _amountDonut(salesByCategory(list, prods)),
          ),
          ReportList<Tally>(
            title: 'Sales by product',
            caption: '${byProduct.length} products sold',
            items: byProduct,
            searchText: (t) => '${t.label} ${t.sub}',
            sorts: [
              ReportSort('Revenue', (a, b) => b.amount.compareTo(a.amount)),
              ReportSort(
                'Quantity',
                (a, b) => b.quantity.compareTo(a.quantity),
              ),
              ReportSort(
                'Name',
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              ),
            ],
            row: (t, i) => _RankRow(
              rank: i + 1,
              title: t.label,
              subtitle: t.sub.isEmpty ? 'Uncategorised' : t.sub,
              value: rupees(t.amount),
              valueSub: '${t.quantity} sold',
            ),
          ),
          ReportList<Sale>(
            title: 'Invoices',
            caption: '${list.length} in this period',
            items: list,
            searchText: (s) =>
                '${s.customerName ?? ''} ${s.invoiceType ?? ''} ${s.paymentStatus} ${s.paymentType ?? ''}',
            sorts: [
              ReportSort('Newest', (a, b) => b.billDate.compareTo(a.billDate)),
              ReportSort('Oldest', (a, b) => a.billDate.compareTo(b.billDate)),
              ReportSort(
                'Highest',
                (a, b) => b.totalAmount.compareTo(a.totalAmount),
              ),
              ReportSort(
                'Lowest',
                (a, b) => a.totalAmount.compareTo(b.totalAmount),
              ),
            ],
            row: (s, _) => ReportRow(
              icon: Icons.receipt_rounded,
              color: s.paymentStatus.toLowerCase() == 'paid'
                  ? AppColors.positive
                  : AppColors.brandDeep,
              title: s.customerName?.isNotEmpty == true
                  ? s.customerName!
                  : 'Walk-in',
              subtitle:
                  '${_day.format(s.billDate)} · ${_cap(s.paymentStatus)}'
                  '${s.paymentType == null ? '' : ' · ${s.paymentType}'}',
              trailing: rupees(s.totalAmount),
            ),
          ),
        ];
      },
    );
  }
}

// ── 2. Expense report ─────────────────────────────────────────────────────

class CompanyExpenseReport extends ConsumerWidget {
  const CompanyExpenseReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    return CompanyReportScreen(
      loading: expenses.isLoading && !expenses.hasValue,
      error: expenses.hasValue ? null : expenses.error,
      onRetry: () => ref.invalidate(expensesProvider),
      body: (period) {
        final now = DateTime.now();
        final list = [
          for (final e in expenses.valueOrNull ?? const <Expense>[])
            if (inPeriod(e.expenseDate, period, now)) e,
        ];
        final total = list.fold<double>(0, (a, e) => a + e.amount);
        final byCategory = expensesByCategory(list);
        return [
          ReportSummary([
            ReportStat(
              Icons.receipt_long_rounded,
              'Total expenses',
              rupees(total),
              AppColors.brand,
            ),
            ReportStat(
              Icons.format_list_numbered_rounded,
              'Entries',
              '${list.length}',
              AppColors.positive,
            ),
            ReportStat(
              Icons.functions_rounded,
              'Avg entry',
              rupees(list.isEmpty ? 0 : total / list.length),
              AppColors.brandDeep,
            ),
            ReportStat(
              Icons.category_rounded,
              'Top category',
              byCategory.isEmpty ? '—' : byCategory.first.label,
              AppColors.brandBlack,
            ),
          ]),
          ReportCard(
            title: 'Expenses by date',
            caption: 'Amount spent',
            child: ReportTrendChart(
              buckets: amountBuckets(
                [for (final e in list) (e.expenseDate, e.amount)],
                period,
                now,
              ),
              valueLabel: _money,
            ),
          ),
          ReportCard(
            title: 'Expenses by category',
            caption: 'Share of spend',
            child: _amountDonut(byCategory),
          ),
          ReportList<Tally>(
            title: 'Category totals',
            items: byCategory,
            sorts: [
              ReportSort('Amount', (a, b) => b.amount.compareTo(a.amount)),
              ReportSort('Entries', (a, b) => b.count.compareTo(a.count)),
              ReportSort(
                'Name',
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              ),
            ],
            row: (t, i) => _RankRow(
              rank: i + 1,
              title: t.label,
              subtitle:
                  '${t.count} entr${t.count == 1 ? 'y' : 'ies'}'
                  '${total > 0 ? ' · ${(t.amount / total * 100).round()}% of spend' : ''}',
              value: rupees(t.amount),
            ),
          ),
          ReportList<Expense>(
            title: 'Expenses',
            caption: '${list.length} in this period',
            items: list,
            searchText: (e) =>
                '${e.title} ${e.category} ${e.paymentMethod ?? ''} ${e.notes ?? ''}',
            sorts: [
              ReportSort(
                'Newest',
                (a, b) => b.expenseDate.compareTo(a.expenseDate),
              ),
              ReportSort(
                'Oldest',
                (a, b) => a.expenseDate.compareTo(b.expenseDate),
              ),
              ReportSort('Highest', (a, b) => b.amount.compareTo(a.amount)),
              ReportSort('Lowest', (a, b) => a.amount.compareTo(b.amount)),
            ],
            row: (e, _) => ReportRow(
              icon: Icons.receipt_long_rounded,
              color: AppColors.brand,
              title: e.title,
              subtitle:
                  '${e.category.isEmpty ? 'Other' : e.category} · ${_day.format(e.expenseDate)}'
                  '${e.paymentMethod == null ? '' : ' · ${e.paymentMethod}'}',
              trailing: rupees(e.amount),
            ),
          ),
        ];
      },
    );
  }
}

// ── 3. Customer report ────────────────────────────────────────────────────

class CompanyCustomerReport extends ConsumerWidget {
  const CompanyCustomerReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final sales = ref.watch(salesProvider);
    final parts = [customers, sales];
    return CompanyReportScreen(
      loading: parts.any((p) => p.isLoading && !p.hasValue),
      error: parts.where((p) => !p.hasValue && p.hasError).firstOrNull?.error,
      onRetry: () {
        ref.invalidate(customersProvider);
        ref.invalidate(salesProvider);
      },
      body: (period) {
        final now = DateTime.now();
        final all = customers.valueOrNull ?? const <Customer>[];
        final added = [
          for (final c in all)
            if (inPeriod(c.createdAt, period, now)) c,
        ];
        final periodSales = [
          for (final s in sales.valueOrNull ?? const <Sale>[])
            if (inPeriod(s.billDate, period, now)) s,
        ];
        final purchases = purchasesByCustomer(periodSales, all);
        final buyers = purchases.where((t) => t.label != 'Walk-in').length;
        final revenue = purchases.fold<double>(0, (a, t) => a + t.amount);
        return [
          ReportSummary([
            ReportStat(
              Icons.people_alt_rounded,
              'Total customers',
              '${all.length}',
              AppColors.brand,
              allTime: true,
            ),
            ReportStat(
              Icons.person_add_alt_1_rounded,
              'New customers',
              '${added.length}',
              AppColors.positive,
            ),
            ReportStat(
              Icons.shopping_bag_rounded,
              'Buying customers',
              '$buyers',
              AppColors.brandDeep,
            ),
            ReportStat(
              Icons.functions_rounded,
              'Avg spend',
              rupees(purchases.isEmpty ? 0 : revenue / purchases.length),
              AppColors.brandBlack,
            ),
          ]),
          ReportList<Tally>(
            title: 'Customer purchases',
            caption: 'Invoices and spend in this period',
            items: purchases,
            searchText: (t) => '${t.label} ${t.sub}',
            sorts: [
              ReportSort('Spend', (a, b) => b.amount.compareTo(a.amount)),
              ReportSort('Invoices', (a, b) => b.count.compareTo(a.count)),
              ReportSort(
                'Recent',
                (a, b) =>
                    (b.last ?? DateTime(0)).compareTo(a.last ?? DateTime(0)),
              ),
              ReportSort(
                'Name',
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              ),
            ],
            row: (t, i) => _RankRow(
              rank: i + 1,
              title: t.label,
              subtitle: [
                if (t.sub.isNotEmpty) t.sub,
                '${t.count} invoice${t.count == 1 ? '' : 's'}',
                if (t.last != null)
                  'last ${DateFormat('d MMM').format(t.last!)}',
              ].join(' · '),
              value: rupees(t.amount),
            ),
          ),
          ReportList<Customer>(
            title: 'New customers',
            caption: '${added.length} added in this period',
            items: added,
            searchText: (c) =>
                '${c.name} ${c.shopName ?? ''} ${c.phone ?? ''} ${c.email ?? ''}',
            sorts: [
              ReportSort(
                'Newest',
                (a, b) => b.createdAt.compareTo(a.createdAt),
              ),
              ReportSort(
                'Name',
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
            ],
            row: (c, _) => ReportRow(
              icon: Icons.person_rounded,
              color: AppColors.positive,
              title: c.name,
              subtitle: [
                if (c.shopName?.isNotEmpty == true) c.shopName!,
                if (c.phone?.isNotEmpty == true) c.phone!,
              ].join(' · '),
              trailing: DateFormat('d MMM').format(c.createdAt),
            ),
          ),
        ];
      },
    );
  }
}

// ── 4. Product / inventory report ─────────────────────────────────────────

class CompanyProductReport extends ConsumerWidget {
  const CompanyProductReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(salesProvider);
    final parts = [products, sales];
    return CompanyReportScreen(
      loading: parts.any((p) => p.isLoading && !p.hasValue),
      error: parts.where((p) => !p.hasValue && p.hasError).firstOrNull?.error,
      onRetry: () {
        ref.invalidate(productsProvider);
        ref.invalidate(salesProvider);
      },
      body: (period) {
        final now = DateTime.now();
        final all = products.valueOrNull ?? const <Product>[];
        final active = all
            .where((p) => p.status.toLowerCase() == 'active')
            .length;
        final periodSales = [
          for (final s in sales.valueOrNull ?? const <Sale>[])
            if (inPeriod(s.billDate, period, now)) s,
        ];
        final sold = salesByProduct(periodSales, all);
        final byCategory = <String, int>{};
        for (final p in all) {
          final c = p.category.isEmpty ? 'Uncategorised' : p.category;
          byCategory[c] = (byCategory[c] ?? 0) + 1;
        }
        final cats = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return [
          ReportSummary([
            ReportStat(
              Icons.checkroom_rounded,
              'Total products',
              '${all.length}',
              AppColors.brand,
              allTime: true,
            ),
            ReportStat(
              Icons.check_circle_rounded,
              'Active',
              '$active',
              AppColors.positive,
              allTime: true,
            ),
            ReportStat(
              Icons.pause_circle_rounded,
              'Inactive',
              '${all.length - active}',
              AppColors.brandBlack,
              allTime: true,
            ),
            ReportStat(
              Icons.shopping_cart_checkout_rounded,
              'Units sold',
              '${sold.fold<int>(0, (a, t) => a + t.quantity)}',
              AppColors.brandDeep,
            ),
          ]),
          ReportCard(
            title: 'Stock summary',
            caption: 'Right now',
            allTime: true,
            child: _StockSummary(all),
          ),
          ReportList<Product>(
            title: 'Low & out of stock',
            caption:
                '${all.where((p) => p.isOutOfStock || p.isLowStock).length} need restocking',
            allTime: true,
            items: [
              for (final p in all)
                if (p.isOutOfStock || p.isLowStock) p,
            ],
            emptyText: 'Everything is well stocked',
            searchText: (p) => '${p.productName} ${p.category}',
            sorts: [
              ReportSort(
                'Lowest first',
                (a, b) => a.stockQuantity.compareTo(b.stockQuantity),
              ),
              ReportSort(
                'Name',
                (a, b) => a.productName.toLowerCase().compareTo(
                  b.productName.toLowerCase(),
                ),
              ),
            ],
            row: (p, _) => ReportRow(
              icon: p.isOutOfStock
                  ? Icons.remove_shopping_cart_rounded
                  : Icons.warning_amber_rounded,
              color: p.isOutOfStock
                  ? AppColors.brandBlack
                  : AppColors.brandDeep,
              title: p.productName,
              subtitle:
                  '${p.category.isEmpty ? 'Uncategorised' : p.category} · alert at ${p.lowStockThreshold}',
              trailing: p.isOutOfStock
                  ? 'Out · ${p.stockQuantity}'
                  : '${p.stockQuantity} left',
            ),
          ),
          ReportCard(
            title: 'Products by category',
            allTime: true,
            child: ReportBreakdown([
              for (final (i, e) in cats.take(5).indexed)
                BreakdownItem(e.key, e.value, _palette[i % _palette.length]),
              if (cats.length > 5)
                BreakdownItem(
                  'Others',
                  cats.skip(5).fold(0, (a, e) => a + e.value),
                  AppColors.textHint,
                ),
            ]),
          ),
          ReportList<Tally>(
            title: 'Product sales',
            caption: '${sold.length} of ${all.length} products sold',
            items: sold,
            searchText: (t) => '${t.label} ${t.sub}',
            sorts: [
              ReportSort('Revenue', (a, b) => b.amount.compareTo(a.amount)),
              ReportSort(
                'Quantity',
                (a, b) => b.quantity.compareTo(a.quantity),
              ),
              ReportSort(
                'Name',
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              ),
            ],
            row: (t, i) => _RankRow(
              rank: i + 1,
              title: t.label,
              subtitle:
                  '${t.sub.isEmpty ? 'Uncategorised' : t.sub}'
                  '${t.last == null ? '' : ' · last sold ${DateFormat('d MMM').format(t.last!)}'}',
              value: rupees(t.amount),
              valueSub: '${t.quantity} sold',
            ),
          ),
        ];
      },
    );
  }
}

// ── 5. Employee report ────────────────────────────────────────────────────

class CompanyEmployeeReport extends ConsumerWidget {
  const CompanyEmployeeReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    return CompanyReportScreen(
      loading: employees.isLoading && !employees.hasValue,
      error: employees.hasValue ? null : employees.error,
      onRetry: () => ref.invalidate(employeesProvider),
      body: (period) {
        final now = DateTime.now();
        final all = employees.valueOrNull ?? const <Employee>[];
        bool isActive(Employee e) => e.status.toLowerCase() == 'active';
        final joined = [
          for (final e in all)
            if (inPeriod(e.joiningDate ?? e.createdAt, period, now)) e,
        ];
        Map<String, int> countBy(String? Function(Employee) f) {
          final m = <String, int>{};
          for (final e in all) {
            final k = f(e)?.trim();
            final key = k == null || k.isEmpty ? 'Not set' : k;
            m[key] = (m[key] ?? 0) + 1;
          }
          return m;
        }

        List<BreakdownItem> items(Map<String, int> m) {
          final sorted = m.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return [
            for (final (i, e) in sorted.take(6).indexed)
              BreakdownItem(
                _cap(e.key),
                e.value,
                _palette[i % _palette.length],
              ),
          ];
        }

        final active = all.where(isActive).length;
        return [
          ReportSummary([
            ReportStat(
              Icons.badge_rounded,
              'Total employees',
              '${all.length}',
              AppColors.brand,
              allTime: true,
            ),
            ReportStat(
              Icons.check_circle_rounded,
              'Active',
              '$active',
              AppColors.positive,
              allTime: true,
            ),
            ReportStat(
              Icons.person_off_rounded,
              'Inactive / on leave',
              '${all.length - active}',
              AppColors.brandBlack,
              allTime: true,
            ),
            ReportStat(
              Icons.person_add_alt_1_rounded,
              'Joined',
              '${joined.length}',
              AppColors.brandDeep,
            ),
          ]),
          ReportCard(
            title: 'By status',
            allTime: true,
            child: ReportBreakdown(items(countBy((e) => e.status))),
          ),
          ReportCard(
            title: 'By department',
            allTime: true,
            child: ReportBreakdown(items(countBy((e) => e.department))),
          ),
          ReportList<Employee>(
            title: 'Employees',
            caption: '${all.length} in total',
            allTime: true,
            items: all,
            searchText: (e) =>
                '${e.fullName} ${e.employeeCode} ${e.department ?? ''} ${e.designation ?? ''} ${e.status}',
            sorts: [
              ReportSort(
                'Name',
                (a, b) => a.fullName.toLowerCase().compareTo(
                  b.fullName.toLowerCase(),
                ),
              ),
              ReportSort(
                'Newest joined',
                (a, b) => (b.joiningDate ?? b.createdAt).compareTo(
                  a.joiningDate ?? a.createdAt,
                ),
              ),
              ReportSort(
                'Department',
                (a, b) => (a.department ?? '').compareTo(b.department ?? ''),
              ),
            ],
            row: (e, _) => ReportRow(
              icon: Icons.person_rounded,
              color: isActive(e) ? AppColors.positive : AppColors.brandBlack,
              title: e.fullName,
              subtitle: [
                e.employeeCode,
                if (e.department?.isNotEmpty == true) e.department!,
                if (e.designation?.isNotEmpty == true) e.designation!,
              ].join(' · '),
              trailing: _cap(e.status),
            ),
          ),
          const ReportNote(
            'Attendance and other employee activity need the attendance module, which is off for now.',
          ),
        ];
      },
    );
  }
}

// ── 6. Profit & loss ──────────────────────────────────────────────────────

String _pct(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}%';

class CompanyProfitLossReport extends ConsumerWidget {
  const CompanyProfitLossReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final expenses = ref.watch(expensesProvider);
    final products = ref.watch(productsProvider);
    final parts = [sales, expenses, products];
    return CompanyReportScreen(
      loading: parts.any((p) => p.isLoading && !p.hasValue),
      error: parts.where((p) => !p.hasValue && p.hasError).firstOrNull?.error,
      onRetry: () {
        ref.invalidate(salesProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(productsProvider);
      },
      body: (period) {
        final now = DateTime.now();
        final s = [
          for (final x in sales.valueOrNull ?? const <Sale>[])
            if (inPeriod(x.billDate, period, now)) x,
        ];
        final e = [
          for (final x in expenses.valueOrNull ?? const <Expense>[])
            if (inPeriod(x.expenseDate, period, now)) x,
        ];
        final prods = products.valueOrNull ?? const <Product>[];
        final pl = ProfitLoss.of(s, e, prods);
        final rows = profitByPeriod(s, e, prods, period, now);
        final byProduct = salesByProduct(s, prods);
        return [
          ReportSummary([
            ReportStat(
              Icons.point_of_sale_rounded,
              'Net sales',
              rupees(pl.netSales),
              AppColors.brand,
            ),
            ReportStat(
              Icons.trending_up_rounded,
              'Gross profit · ${_pct(pl.margin(pl.grossProfit))}',
              rupees(pl.grossProfit),
              AppColors.positive,
            ),
            ReportStat(
              Icons.receipt_long_rounded,
              'Expenses',
              rupees(pl.expenses),
              AppColors.brandDeep,
            ),
            ReportStat(
              pl.netProfit >= 0
                  ? Icons.savings_rounded
                  : Icons.trending_down_rounded,
              '${pl.netProfit >= 0 ? 'Net profit' : 'Net loss'} · ${_pct(pl.margin(pl.netProfit))}',
              rupees(pl.netProfit),
              pl.netProfit >= 0 ? AppColors.positive : AppColors.brandBlack,
            ),
          ]),
          ReportCard(
            title: 'Profit & loss statement',
            caption: '${s.length} invoices · ${e.length} expenses',
            child: _Statement(pl),
          ),
          if (pl.uncostedLines > 0)
            ReportNote(
              '${pl.uncostedLines} sold item${pl.uncostedLines == 1 ? '' : 's'} '
              'have no cost price, so they count as zero cost — set cost prices on '
              'those products for an exact gross profit.',
            ),
          ReportList<ProfitRow>(
            title: 'By period',
            caption: 'Net sales − cost of goods − expenses',
            items: rows.reversed.toList(), // newest first
            emptyText: 'No sales or expenses in this period',
            row: (r, _) {
              final profit = r.sales - r.cogs - r.expenses;
              return _ProfitRowTile(
                label: r.label,
                detail:
                    'Sales ${_money(r.sales)} · Cost ${_money(r.cogs)} · Exp ${_money(r.expenses)}',
                profit: profit,
              );
            },
          ),
          ReportList<Tally>(
            title: 'Gross profit by product',
            caption: 'Revenue − cost of goods sold',
            items: byProduct,
            searchText: (t) => '${t.label} ${t.sub}',
            sorts: [
              ReportSort(
                'Profit',
                (a, b) => (b.amount - b.cost).compareTo(a.amount - a.cost),
              ),
              ReportSort(
                'Margin',
                (a, b) => ((b.amount - b.cost) / (b.amount == 0 ? 1 : b.amount))
                    .compareTo(
                      (a.amount - a.cost) / (a.amount == 0 ? 1 : a.amount),
                    ),
              ),
              ReportSort('Revenue', (a, b) => b.amount.compareTo(a.amount)),
            ],
            row: (t, i) => _RankRow(
              rank: i + 1,
              title: t.label,
              subtitle: 'Revenue ${rupees(t.amount)} · Cost ${rupees(t.cost)}',
              value: rupees(t.amount - t.cost),
              valueSub: t.amount == 0
                  ? null
                  : _pct((t.amount - t.cost) / t.amount * 100),
            ),
          ),
          const ReportNote(
            'Cost of goods uses the cost saved on each sale line (older lines: the product\'s current cost). Sales are counted without the tax collected.',
          ),
        ];
      },
    );
  }
}

/// The P&L statement: lines with − / =, subtotals bold, net result coloured.
class _Statement extends StatelessWidget {
  final ProfitLoss pl;
  const _Statement(this.pl);

  @override
  Widget build(BuildContext context) {
    Widget line(
      String label,
      double v, {
      String sign = '',
      bool total = false,
      Color? color,
    }) => Padding(
      padding: EdgeInsets.symmetric(vertical: total ? 8 : 6),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              sign,
              style: TextStyle(
                color: AppColors.textHint,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: total ? AppColors.ink : AppColors.textSecondary,
                fontSize: total ? 14 : 13,
                fontWeight: total ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            rupees(v),
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: total ? 15 : 13,
              fontWeight: total ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    Widget rule() => Divider(height: 1, color: AppColors.border);
    final net = pl.netProfit;
    return Column(
      children: [
        line('Sales (incl. tax)', pl.grossSales),
        line('Tax collected', pl.tax, sign: '−'),
        rule(),
        line('Net sales', pl.netSales, sign: '=', total: true),
        line('Cost of goods sold', pl.cogs, sign: '−'),
        rule(),
        line(
          'Gross profit  ${_pct(pl.margin(pl.grossProfit))}',
          pl.grossProfit,
          sign: '=',
          total: true,
        ),
        line('Expenses', pl.expenses, sign: '−'),
        rule(),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (net >= 0 ? AppColors.positive : AppColors.brandBlack)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: line(
            '${net >= 0 ? 'Net profit' : 'Net loss'}  ${_pct(pl.margin(net))}',
            net,
            sign: '=',
            total: true,
            color: net >= 0 ? AppColors.positive : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _ProfitRowTile extends StatelessWidget {
  final String label;
  final String detail;
  final int profit;
  const _ProfitRowTile({
    required this.label,
    required this.detail,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    final up = profit >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (up ? AppColors.positive : AppColors.brandBlack)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 17,
              color: up ? AppColors.positive : AppColors.brandBlack,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(profit),
            style: TextStyle(
              color: up ? AppColors.positive : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// In stock / low / out counts, units on hand and their value at cost.
class _StockSummary extends StatelessWidget {
  final List<Product> products;
  const _StockSummary(this.products);

  @override
  Widget build(BuildContext context) {
    final out = products.where((p) => p.isOutOfStock).length;
    final low = products.where((p) => p.isLowStock).length;
    final units = products.fold<int>(
      0,
      (a, p) => a + (p.stockQuantity > 0 ? p.stockQuantity : 0),
    );
    final value = products.fold<double>(
      0,
      (a, p) => a + (p.stockQuantity > 0 ? p.stockQuantity * p.costPrice : 0),
    );
    Widget cell(String label, String v, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                v,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            cell(
              'In stock',
              '${products.length - out - low}',
              AppColors.positive,
            ),
            const SizedBox(width: 8),
            cell('Low stock', '$low', AppColors.brandDeep),
            const SizedBox(width: 8),
            cell('Out of stock', '$out', AppColors.brandBlack),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            cell('Units on hand', '$units', AppColors.brand),
            const SizedBox(width: 8),
            cell('Stock value at cost', rupees(value), AppColors.brand),
          ],
        ),
      ],
    );
  }
}
