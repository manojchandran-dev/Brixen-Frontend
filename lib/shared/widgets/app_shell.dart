import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_bottom_nav.dart';
import 'app_drawer.dart';

/// The drawer + bottom-nav shell shared by the Dashboard/Report/More
/// routes — every role gets the exact same shell; only [body] differs
/// per role, decided by the page that uses this.
class AppShell extends StatelessWidget {
  final int activeIndex;
  final Widget body;
  const AppShell({super.key, required this.activeIndex, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      drawer: AppDrawer(),
      bottomNavigationBar: AppBottomNav(activeIndex: activeIndex),
      body: SafeArea(
        // `bottom: false` — these pages have no AppBar, and combined with
        // `extendBody: true` + AppBottomNav's own internal SafeArea, the
        // default `SafeArea(bottom: true)` computes a bottom inset large
        // enough to collapse the whole body (blank page, no error).
        bottom: false,
        child: body,
      ),
    );
  }
}
