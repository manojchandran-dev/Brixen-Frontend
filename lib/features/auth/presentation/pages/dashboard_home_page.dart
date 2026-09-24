import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../dashboard/presentation/pages/company_admin/company_admin_dashboard_page.dart';
import '../../../dashboard/presentation/pages/employee/employee_dashboard_page.dart';
import '../../../dashboard/presentation/pages/superadmin/superadmin_dashboard_page.dart';
import '../../domain/entities/user_role.dart';
import '../../../../core/services/session_service.dart';

/// The shared Dashboard tab (index 0) — same route for every role, each
/// rendering its own role-appropriate body inside the common [AppShell].
/// The actual per-role screens live under
/// `features/dashboard/presentation/pages/<role>/`.
class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  // AppColors' values are plain static getters, not something Flutter's
  // element tree can detect changed on its own — a widget only picks up
  // the new theme's colors if it's actually rebuilt. This page (and
  // Report/More) used to have no reason to rebuild on a theme toggle, so
  // only whichever screen you happened to toggle it FROM (e.g. More,
  // whose AppMenuBody already listens for itself) updated live; every
  // other route stayed on the old colors until next visited. Listening
  // here — and constructing every role body fresh (no `const`) so the
  // rebuild actually cascades instead of Flutter skipping an unchanged
  // const subtree — fixes that for good.
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

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), backgroundColor: AppColors.dangerFill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activeIndex: 0,
      body: switch (Session.role) {
        UserRole.superAdmin => const SuperadminDashboardPage(),
        UserRole.companyAdmin => CompanyAdminDashboardPage(onIconTap: (l) => _comingSoon(context, l)),
        UserRole.employee => EmployeeDashboardPage(onIconTap: (l) => _comingSoon(context, l)),
      },
    );
  }
}
