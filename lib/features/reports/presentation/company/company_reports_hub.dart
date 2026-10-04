import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'company_report_pages.dart';

/// Company Reports: the six reports on one page, one tab each — tap a tab
/// or swipe sideways. Each tab has the date filter (shared across tabs) and
/// its detailed lists. The Dashboard stays the quick status view.
class CompanyReportsHub extends StatelessWidget {
  const CompanyReportsHub({super.key});

  static const _tabs = [
    (Icons.point_of_sale_rounded, 'Sales'),
    (Icons.receipt_long_rounded, 'Expenses'),
    (Icons.account_balance_wallet_rounded, 'Profit & Loss'),
    (Icons.people_alt_rounded, 'Customers'),
    (Icons.checkroom_rounded, 'Products'),
    (Icons.badge_rounded, 'Employees'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          // Report tabs: floating chips, the selected one a solid blue pill
          // (the date filter inside each tab is a slim green underline row).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDeep],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              splashBorderRadius: BorderRadius.circular(20),
              tabs: [
                for (final (icon, label) in _tabs)
                  Tab(
                    height: 40,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 17),
                        const SizedBox(width: 6),
                        Text(label),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                CompanySalesReport(),
                CompanyExpenseReport(),
                CompanyProfitLossReport(),
                CompanyCustomerReport(),
                CompanyProductReport(),
                CompanyEmployeeReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
