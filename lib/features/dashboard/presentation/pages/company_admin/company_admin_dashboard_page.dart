import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/services/session_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/session_icon.dart';
import '../../../../../shared/widgets/skeleton.dart';
import '../../../../customers/presentation/providers/customers_provider.dart';
import '../../../../employees/presentation/providers/employees_provider.dart';
import '../../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../../notifications/presentation/widgets/inbox_bell.dart';
import '../../../../permissions/presentation/providers/module_access_provider.dart';
import '../../../../products/domain/entities/product.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../sales/presentation/providers/sales_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'company_dashboard_stats.dart';

// ── companyAdmin dashboard: today's business status at a glance ──────────
// Header, summary, quick actions, today's activity, inventory alert, and a
// small sales/expenses/net status. No analysis — that's the Reports tab.
// Totals: GET /dashboard/summary. Today's figures: the module lists the app
// already loads (company_dashboard_stats.dart).

class CompanyAdminDashboardPage extends ConsumerWidget {
  final void Function(String) onIconTap;
  const CompanyAdminDashboardPage({super.key, required this.onIconTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider).valueOrNull;
    final sales = ref.watch(salesProvider);
    final expenses = ref.watch(expensesProvider);
    final customers = ref.watch(customersProvider);
    final employees = ref.watch(employeesProvider);
    final products = ref.watch(productsProvider);

    final parts = [sales, expenses, customers, employees];
    final loading = parts.any((p) => !p.hasValue && !p.hasError);
    final failed = parts.any((p) => !p.hasValue && p.hasError);
    final today = loading
        ? null
        : TodayStats.compute(
            now: DateTime.now(),
            sales: sales.valueOrNull ?? const [],
            expenses: expenses.valueOrNull ?? const [],
            customers: customers.valueOrNull ?? const [],
            employees: employees.valueOrNull ?? const [],
          );

    void refresh() {
      ref.invalidate(dashboardSummaryProvider);
      for (final p in [
        salesProvider,
        expensesProvider,
        customersProvider,
        employeesProvider,
        productsProvider,
      ]) {
        ref.invalidate(p);
      }
    }

    // Totals: the summary API, else the loaded list's length.
    final employeesTotal =
        summary?.totalEmployees ?? employees.valueOrNull?.length;
    final customersTotal =
        summary?.totalCustomers ?? customers.valueOrNull?.length;
    final productsTotal =
        summary?.totalProducts ?? products.valueOrNull?.length;

    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          _Header(onSearch: () => onIconTap('Search')),
          const SizedBox(height: 16),
          const _Greeting(),
          if (failed) ...[
            const SizedBox(height: 14),
            _LoadIssue(onRetry: refresh),
          ],
          const SizedBox(height: 22),
          const _SectionLabel('Business summary', Icons.insights_rounded),
          const SizedBox(height: 12),
          _Summary(
            employees: employeesTotal,
            customers: customersTotal,
            products: productsTotal,
            today: today,
          ),
          const SizedBox(height: 22),
          const _QuickActions(),
          const SizedBox(height: 22),
          const _SectionLabel("Today's activity", Icons.bolt_rounded),
          const SizedBox(height: 12),
          _TodayActivity(activity: today?.activity),
          const SizedBox(height: 22),
          const _SectionLabel('Inventory alert', Icons.inventory_2_rounded),
          const SizedBox(height: 12),
          _InventoryAlert(products: products.valueOrNull),
          const SizedBox(height: 22),
          const _SectionLabel(
            "Today's status",
            Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 12),
          _BusinessStatus(today: today),
        ],
      ),
    );
  }
}

// ── Shared bits ───────────────────────────────────────────────────────────

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(20),
  boxShadow: AppColors.shadows([
    BoxShadow(
      color: AppColors.shadowDark.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.highlightShadow(0.9),
      blurRadius: 8,
      offset: const Offset(-4, -4),
    ),
  ]),
);

/// Section heading: gradient accent bar + tinted icon + title.
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brand, AppColors.positive],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 17, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Header / greeting ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onSearch;
  const _Header({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]),
            ),
            child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                weekdayDateLabel(DateTime.now()),
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onSearch,
          child: Icon(Icons.search_rounded, color: AppColors.ink, size: 24),
        ),
        const SizedBox(width: 18),
        const InboxBell(),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? [AppColors.brandDeep, AppColors.brandBlack]
              : [AppColors.brand, AppColors.positive],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${greetingPrefix()}, ${Session.ownerName ?? 'Admin'} 👋',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (Session.companyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    Session.companyName!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 46,
            height: 46,
            child: FittedBox(child: SessionIcon(session: currentSession())),
          ),
        ],
      ),
    );
  }
}

class _LoadIssue extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadIssue({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Some data couldn't load — figures may be incomplete.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Business summary ──────────────────────────────────────────────────────

/// Three count cards (Employees / Customers / Products), then the two
/// money cards (today's sales / expenses). Null value = still loading.
class _Summary extends StatelessWidget {
  final int? employees, customers, products;
  final TodayStats? today;
  const _Summary({
    required this.employees,
    required this.customers,
    required this.products,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.badge_rounded,
                label: 'Employees',
                value: employees,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountCard(
                icon: Icons.people_alt_rounded,
                label: 'Customers',
                value: customers,
                color: AppColors.positive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountCard(
                icon: Icons.checkroom_rounded,
                label: 'Products',
                value: products,
                color: AppColors.brandDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MoneyCard(
                icon: Icons.point_of_sale_rounded,
                label: "Today's sales",
                value: today?.sales,
                note: today == null
                    ? null
                    : '${today!.invoices} invoice${today!.invoices == 1 ? '' : 's'}',
                // Green: money in.
                color: AppColors.positive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyCard(
                icon: Icons.receipt_long_rounded,
                label: "Today's expenses",
                value: today?.expenses,
                note: 'Spent today',
                // Blue: money out.
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tinted count card: soft colour fill, coloured icon badge and number,
/// a big faded icon in the corner.
class _CountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  const _CountCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: AppColors.isDark ? 0.22 : 0.10),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(icon, size: 64, color: color.withValues(alpha: 0.10)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.accentGradient(color),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: Colors.white),
                  ),
                  const Spacer(),
                  value == null
                      ? const Shimmer(child: SkeletonBox(width: 40, height: 20))
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            NumberFormat.decimalPattern('en_IN').format(value),
                            style: TextStyle(
                              color: AppColors.isDark ? AppColors.ink : color,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient money card (green sales / blue expenses) with a faded icon.
class _MoneyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? value;
  final String? note;
  final Color color;
  const _MoneyCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.accentGradient(color);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -16,
              child: Icon(
                icon,
                size: 84,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  value == null
                      ? Container(
                          width: 90,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rupees(value!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                  const SizedBox(height: 4),
                  if (note != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only what this user may create; alternating blue / green.
    final actions = [
      (
        'Employees',
        'Employee',
        Icons.person_add_alt_1_rounded,
        AppRouter.createEmployee,
      ),
      ('Sales', 'Sale', Icons.add_shopping_cart_rounded, AppRouter.createSale),
      (
        'Customers',
        'Customer',
        Icons.group_add_rounded,
        AppRouter.createCustomer,
      ),
      ('Products', 'Product', Icons.checkroom_rounded, AppRouter.createProduct),
      ('Expenses', 'Expense', Icons.post_add_rounded, AppRouter.createExpense),
    ].where((a) => ref.watch(moduleAccessProvider(a.$1)).create).toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Quick actions', Icons.flash_on_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              for (final (i, (_, label, icon, route)) in actions.indexed)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.accentGradient(
                                  i.isEven
                                      ? AppColors.brand
                                      : AppColors.positive,
                                ),
                              ),
                              boxShadow: AppColors.shadows([
                                BoxShadow(
                                  color:
                                      (i.isEven
                                              ? AppColors.brand
                                              : AppColors.positive)
                                          .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ]),
                            ),
                            child: Icon(icon, size: 21, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Today's activity ──────────────────────────────────────────────────────

class _TodayActivity extends StatelessWidget {
  /// Null = still loading.
  final List<DashActivity>? activity;
  const _TodayActivity({required this.activity});

  static (IconData, Color) _look(ActivityKind k) => switch (k) {
    ActivityKind.sale => (Icons.point_of_sale_rounded, AppColors.positive),
    ActivityKind.customer => (Icons.person_add_alt_1_rounded, AppColors.brand),
    ActivityKind.employee => (Icons.badge_rounded, AppColors.brandDeep),
    ActivityKind.expense => (Icons.receipt_long_rounded, AppColors.brandLight),
  };

  @override
  Widget build(BuildContext context) {
    final list = activity;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _cardDecoration(),
      child: list == null
          ? Shimmer(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SkeletonBox(width: 36, height: 36, radius: 12),
                          SizedBox(width: 12),
                          Expanded(child: SkeletonBox(height: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            )
          : list.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.positive.withValues(alpha: 0.18),
                          AppColors.brand.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      size: 28,
                      color: AppColors.positive,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nothing yet today',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'New sales, customers, employees and expenses show here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final (i, a) in list.indexed) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.accentGradient(
                                _look(a.kind).$2,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _look(a.kind).$1,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                a.detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('h:mm a').format(a.at),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Inventory alert ───────────────────────────────────────────────────────

/// Low / out of stock counts from the products' stock; tap → Products.
class _InventoryAlert extends StatelessWidget {
  /// Null = still loading.
  final List<Product>? products;
  const _InventoryAlert({required this.products});

  @override
  Widget build(BuildContext context) {
    final list = products;
    final low = list?.where((p) => p.isLowStock).length;
    final out = list?.where((p) => p.isOutOfStock).length;
    Widget tile(IconData icon, String label, int? count, Color color) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(alpha: AppColors.isDark ? 0.2 : 0.10),
                AppColors.surface,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.accentGradient(color),
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == null ? '…' : '$count',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return GestureDetector(
      onTap: () => context.push(AppRouter.inventory),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                tile(
                  Icons.trending_down_rounded,
                  'Low stock',
                  low,
                  AppColors.brand,
                ),
                const SizedBox(width: 10),
                tile(
                  Icons.remove_shopping_cart_rounded,
                  'Out of stock',
                  out,
                  AppColors.positive,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    list == null
                        ? 'Checking stock…'
                        : (low ?? 0) + (out ?? 0) == 0
                        ? 'All products are well stocked.'
                        : '${(low ?? 0) + (out ?? 0)} product${(low ?? 0) + (out ?? 0) == 1 ? '' : 's'} need restocking — tap for Inventory.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's status ────────────────────────────────────────────────────────

/// Sales, expenses and what's left (net) — plus one bar showing how much
/// of today's sales the expenses took.
class _BusinessStatus extends StatelessWidget {
  final TodayStats? today;
  const _BusinessStatus({required this.today});

  @override
  Widget build(BuildContext context) {
    final t = today;
    Widget figure(String label, double? v, Color dot) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          v == null
              ? const Shimmer(child: SkeletonBox(width: 60, height: 18))
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupees(v),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ],
      ),
    );

    final share = t == null || t.sales <= 0
        ? 0.0
        : (t.expenses / t.sales).clamp(0.0, 1.0);
    final netUp = t == null || t.net >= 0;
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green→blue strip on top.
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.positive, AppColors.brand],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    figure('Sales', t?.sales, AppColors.positive),
                    figure('Expenses', t?.expenses, AppColors.brand),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.accentGradient(
                            netUp ? AppColors.positive : AppColors.brandDeep,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            t == null ? '…' : rupees(t.net),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        // Kept (green) vs spent (blue), as parts of sales.
                        Expanded(
                          flex: ((1 - share) * 1000).round().clamp(1, 1000),
                          child: Container(color: AppColors.positive),
                        ),
                        if (share > 0)
                          Expanded(
                            flex: (share * 1000).round().clamp(1, 1000),
                            child: Container(color: AppColors.brand),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t == null
                      ? ' '
                      : t.sales <= 0 && t.expenses <= 0
                      ? 'No sales or expenses recorded today'
                      : t.sales <= 0
                      ? 'Expenses recorded, no sales yet today'
                      : 'Expenses are ${(share * 100).round()}% of today\'s sales',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
