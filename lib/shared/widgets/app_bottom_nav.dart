import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// Dashboard / Report / More are each their own route now
/// (AppRouter.dashboard/report/more) — every role lands on the same three
/// paths, with each route deciding its own role-appropriate content. This
/// nav bar navigates between them by default; [onTap] is only kept for
/// `CompaniesPage`'s own internal Companies/Masters drill-down nav, which
/// switches an internal tab index instead of the route.
class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int)? onTap;
  const AppBottomNav({super.key, required this.activeIndex, this.onTap});

  static String _target(int index) => switch (index) {
    2 => AppRouter.report,
    3 => AppRouter.more,
    _ => AppRouter.dashboard,
  };

  /// Current path, or null outside a GoRouter (tests).
  static String? _path(BuildContext context) =>
      GoRouter.maybeOf(context)?.routerDelegate.currentConfiguration.uri.path;

  /// The tab actually showing, from the route — not [activeIndex], which
  /// module pages (Companies, Customers, …) set to a tab they aren't on.
  /// A module page highlights nothing, so every tab stays tappable.
  int _active(BuildContext context) {
    final path = _path(context);
    if (path == null) return activeIndex;
    if (path == AppRouter.more) return 3;
    if (path == AppRouter.report || path.startsWith('${AppRouter.report}/')) {
      return 2;
    }
    if (path == AppRouter.dashboard) return 0;
    return -1;
  }

  void _onTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }
    final target = _target(index);
    // Only a no-op when that exact tab page is already showing.
    if (_path(context) == target) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final active = _active(context);
    // Reads AppColors' own dark-mode flag rather than Theme.of(context) —
    // this widget is passed as `bottomNavigationBar: const AppBottomNav(...)`
    // on every page, and as a const instance it doesn't reliably rebuild
    // off Theme.of(context) when the app-wide theme toggles.
    final isDark = AppColors.isDark;
    // NOTE: no transparent ColoredBox wrapper here — with `extendBody: true`
    // this widget is stretched to the full Scaffold height, and a
    // Container(color: ...) — even fully transparent — always intercepts
    // hit-testing across its whole bounds, silently swallowing every tap
    // (including the AppBar's hamburger) outside the actual nav pill.
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.brand : AppColors.black,
            borderRadius: BorderRadius.circular(36),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavBtn(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: active == 0,
                onTap: () => _onTap(context, 0),
              ),
              // Attendance module disabled for now — uncomment to re-enable.
              // _NavBtn(icon: Icons.access_time_outlined,  activeIcon: Icons.access_time_filled_rounded,  label: 'Attendance', isActive: activeIndex == 1, onTap: () => _onTap(context, 1)),
              _NavBtn(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Report',
                isActive: active == 2,
                onTap: () => _onTap(context, 2),
              ),
              _NavBtn(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'More',
                isActive: active == 3,
                onTap: () => _onTap(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Same pill treatment in both themes — solid bar (black in light mode,
    // brand blue in dark mode) with the active icon inside a filled green
    // circle, so the highlight colour reads consistently either way.
    final iconColor = isActive
        ? AppColors.white
        : Colors.white.withValues(alpha: 0.75);
    return SizedBox(
      width: 52,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? AppColors.positive : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 19,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
