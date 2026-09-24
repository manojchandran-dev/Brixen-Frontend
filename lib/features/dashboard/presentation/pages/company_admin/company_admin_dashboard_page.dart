import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/session_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/session_icon.dart';
import '../../../domain/entities/dashboard_summary.dart';
import '../../providers/dashboard_provider.dart';

// ── companyAdmin: at-a-glance dashboard ──────────────────────────────────
// Deliberately not built from stat "cards" the way Reports is — Sales/
// Expenses/Profit totals live in the Reports tab, not here. This is just a
// snapshot strip (Employees/Customers/Products) plus two plain
// recent-activity lists, so Dashboard reads as a distinct screen instead
// of a second copy of Reports.

class CompanyAdminDashboardPage extends ConsumerWidget {
  final void Function(String) onIconTap;
  const CompanyAdminDashboardPage({super.key, required this.onIconTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single call to GET /dashboard/summary — CompanyScopeInterceptor
    // auto-attaches this session's company_id, so the backend returns the
    // company-scoped branch (employees/customers/products totals + top-3
    // recent sales/expenses, already sorted newest-first) instead of the
    // superAdmin's platform-wide one.
    final summary = ref.watch(dashboardSummaryProvider).valueOrNull;
    final employeesCount = summary?.totalEmployees ?? 0;
    final customersCount = summary?.totalCustomers ?? 0;
    final productsCount = summary?.totalProducts ?? 0;
    final recentSales = summary?.recentSales ?? const <RecentSaleSummary>[];
    final recentExpenses =
        summary?.recentExpenses ?? const <RecentExpenseSummary>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              onTap: () => onIconTap('Search'),
              child: Icon(Icons.search_rounded, color: AppColors.ink, size: 24),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onIconTap('Notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.ink,
                    size: 24,
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.brandBlack,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Gradient greeting hero ────────────────────────────────
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
        const SizedBox(height: 24),

        // ── Company snapshot: Employees / Customers / Products ──────
        Text(
          'Company Snapshot',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _SnapshotStrip(
          employees: employeesCount,
          customers: customersCount,
          products: productsCount,
        ),
        const SizedBox(height: 26),

        // ── Recent Sales ─────────────────────────────────────────
        Text(
          'Recent Sales',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _RecentSalesList(sales: recentSales.take(3).toList()),
        const SizedBox(height: 26),

        // ── Recent Expenses ──────────────────────────────────────
        Text(
          'Recent Expenses',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _RecentExpensesList(expenses: recentExpenses.take(3).toList()),
      ],
    );
  }
}

/// A single bordered strip with internal dividers — deliberately not three
/// separate elevated cards, so this doesn't read as the same component
/// language as Reports' stat cards.
class _SnapshotStrip extends StatelessWidget {
  final int employees;
  final int customers;
  final int products;
  const _SnapshotStrip({
    required this.employees,
    required this.customers,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SnapshotSegment(
            icon: Icons.badge_rounded,
            color: AppColors.brand,
            value: employees,
            label: 'Employees',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotSegment(
            icon: Icons.people_alt_rounded,
            color: AppColors.positive,
            value: customers,
            label: 'Customers',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotSegment(
            icon: Icons.checkroom_rounded,
            color: AppColors.brandDeep,
            value: products,
            label: 'Products',
          ),
        ),
      ],
    );
  }
}

/// A solid colored tile per metric (like Reports' Sales/Expenses cards),
/// just three of them fused into one row instead of the elevated-card
/// treatment, so this still doesn't read as a literal copy of that layout.
class _SnapshotSegment extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _SnapshotSegment({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final shadowDark = Color.lerp(color, AppColors.ink, 0.3)!;
    final shadowLight = Color.lerp(color, Colors.white, 0.4)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(color),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: shadowDark.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ]),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A raised, glossy icon circle — diagonal shade (light top-left → deep
/// bottom-right) plus a soft highlight arc, on top of the usual drop
/// shadow, so it reads as a small embossed button instead of a flat
/// color-filled dot.
class _GlossIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlossIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(color, Colors.black, 0.35)!;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color, deep],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: deep.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ]),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: Container(
              width: 14,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          Icon(icon, size: 16, color: AppColors.white),
        ],
      ),
    );
  }
}

/// Plain divided list rows directly on the page background — no card
/// container — for the same reason as [_SnapshotStrip] above.
class _RecentSalesList extends StatelessWidget {
  final List<RecentSaleSummary> sales;
  const _RecentSalesList({required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return Text(
        'No sales yet.',
        style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
      );
    }
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Column(
      children: sales.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final name = s.customerName.isNotEmpty ? s.customerName : 'Walk-in';
        return Column(
          children: [
            Row(
              children: [
                const _GlossIconBadge(
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('d MMM').format(s.date),
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${fmt.format(s.amount)}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (i != sales.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _RecentExpensesList extends StatelessWidget {
  final List<RecentExpenseSummary> expenses;
  const _RecentExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Text(
        'No expenses yet.',
        style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
      );
    }
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Column(
      children: expenses.asMap().entries.map((e) {
        final i = e.key;
        final x = e.value;
        return Column(
          children: [
            Row(
              children: [
                const _GlossIconBadge(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.brandDeep,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        x.title,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('d MMM').format(x.date),
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${fmt.format(x.amount)}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (i != expenses.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
          ],
        );
      }).toList(),
    );
  }
}
