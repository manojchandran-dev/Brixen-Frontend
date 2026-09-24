import 'package:flutter/material.dart';
import '../../../../../shared/widgets/welcome_dashboard_view.dart';

// ── superAdmin: platform-wide dashboard ──────────────────────────────────
// Thin wrapper around the shared [WelcomeDashboardView] — that widget is
// also reused by the Companies feature (as a company detail header), so it
// stays in shared/widgets rather than moving in here.

class SuperadminDashboardPage extends StatelessWidget {
  const SuperadminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const WelcomeDashboardView();
}
