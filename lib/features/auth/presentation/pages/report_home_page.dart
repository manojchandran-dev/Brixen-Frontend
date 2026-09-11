import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../features/reports/presentation/pages/company_reports_body.dart';
import '../../../../features/reports/presentation/pages/reports_body.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/page_header_bar.dart';
import '../../domain/entities/user_role.dart';

/// The shared Report tab (index 2) — same route for every role, each
/// rendering its own role-appropriate body inside the common [AppShell].
/// [ReportsBody] (superAdmin) and [CompanyReportsBody] (companyAdmin) share
/// the same design but are independently-editable components, matching the
/// Dashboard tab's per-role split. Neither carries its own header, so this
/// page provides one — the hamburger + "Reports" title — uniformly for
/// every role.
class ReportHomePage extends StatefulWidget {
  const ReportHomePage({super.key});

  @override
  State<ReportHomePage> createState() => _ReportHomePageState();
}

class _ReportHomePageState extends State<ReportHomePage> {
  // See dashboard_home_page.dart's identical listener for why this is
  // needed — without it this page never rebuilds on a theme toggle, so it
  // keeps showing stale colors until next visited.
  late final StreamSubscription<ThemeMode> _themeSub;

  @override
  void initState() {
    super.initState();
    _themeSub = themeCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _themeSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activeIndex: 2,
      body: Column(
        children: [
          PageHeaderBar(title: 'Reports'),
          Expanded(
            child: switch (Session.role) {
              UserRole.superAdmin => ReportsBody(),
              UserRole.companyAdmin => CompanyReportsBody(),
              UserRole.employee => ComingSoonView(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  subtitle: 'Reports are on the way.',
                ),
            },
          ),
        ],
      ),
    );
  }
}
