import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'superadmin_report_pages.dart';

/// Superadmin → Reports: every report on one page, one tab each — tap a tab
/// or swipe sideways. (Company admins have their own CompanyReportsBody.)
class SuperadminReportsHub extends StatelessWidget {
  const SuperadminReportsHub({super.key});

  static const _tabs = [
    (Icons.business_rounded, 'Company'),
    (Icons.badge_rounded, 'Users'),
    (Icons.notifications_active_rounded, 'Notifications'),
    (Icons.support_agent_rounded, 'Support'),
    (Icons.forum_rounded, 'Chatbot'),
    (Icons.history_rounded, 'Activity'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          // Main navigation: floating chips, the selected report a solid
          // blue pill (the date filter below is a slim green underline row).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.brand,
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
                CompanyReportPage(),
                UsersReportPage(),
                NotificationReportPage(),
                SupportReportPage(),
                ChatbotReportPage(),
                ActivityReportPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
