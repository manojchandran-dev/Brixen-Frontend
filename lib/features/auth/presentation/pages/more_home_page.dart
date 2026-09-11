import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/app_menu_body.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/page_header_bar.dart';

/// The shared More tab (index 3) — same route, same body for every role.
/// [AppMenuBody] itself reads [Session.role] to show the right name/role
/// badge, so no per-role branching is needed here.
class MoreHomePage extends StatefulWidget {
  const MoreHomePage({super.key});

  @override
  State<MoreHomePage> createState() => _MoreHomePageState();
}

class _MoreHomePageState extends State<MoreHomePage> {
  // [AppMenuBody] already listens for itself, but [PageHeaderBar] — a
  // sibling, not a descendant of it — doesn't, so without this the top
  // header bar stayed on the old theme's colors after a toggle even
  // though the body below it updated. See dashboard_home_page.dart's
  // identical listener for the fuller explanation.
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
      activeIndex: 3,
      body: Column(
        children: [
          PageHeaderBar(title: 'More'),
          const Expanded(child: AppMenuBody()),
        ],
      ),
    );
  }
}
