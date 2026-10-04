import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/session_service.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/navigation/presentation/providers/nav_modules_provider.dart';
import 'app_drawer.dart' show isChatModule;
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// Dashboard / Report / More are each their own route now
/// (AppRouter.dashboard/report/more) — every role lands on the same three
/// paths, with each route deciding its own role-appropriate content. This
/// nav bar navigates between them by default; [onTap] is only kept for
/// `CompaniesPage`'s own internal Companies/Masters drill-down nav, which
/// switches an internal tab index instead of the route.
class AppBottomNav extends ConsumerWidget {
  final int activeIndex;
  final void Function(int)? onTap;
  const AppBottomNav({super.key, required this.activeIndex, this.onTap});

  static String _target(int index) => switch (index) {
    2 => AppRouter.report,
    3 => AppRouter.more,
    4 => AppRouter.chat,
    _ => AppRouter.dashboard,
  };

  /// Path of the route this nav sits in — not the router's global location,
  /// which can still be the previous page while a new one first builds (the
  /// Dashboard↔Report highlight lagged a tab behind). Falls back to that
  /// global location off a GoRouter route, null outside a GoRouter (tests).
  static String? _path(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return GoRouter.maybeOf(
        context,
      )?.routerDelegate.currentConfiguration.uri.path;
    }
  }

  /// The tab actually showing, from the route — not [activeIndex], which
  /// module pages (Companies, Customers, …) set to a tab they aren't on.
  /// A module page highlights nothing, so every tab stays tappable.
  int _active(BuildContext context) {
    final path = _path(context);
    if (path == null) return activeIndex;
    if (path == AppRouter.more) return 3;
    if (path == AppRouter.chat || path.startsWith('${AppRouter.chat}/')) {
      return 4;
    }
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
    // Company users chat in a sheet over the page; superadmin has the list.
    if (index == 4 && !Session.isSuperAdmin) {
      showChatSheet(context);
      return;
    }
    final target = _target(index);
    // Only a no-op when that exact tab page is already showing.
    if (_path(context) == target) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = _active(context);
    // Chat tab only for users whose menu (GET /modules) includes Chat.
    final hasChat =
        ref.watch(navModulesProvider).valueOrNull?.any(isChatModule) ?? false;
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
    final pill = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );
    // Chat sits beside the bar as its own round button, not a fourth tab.
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pill,
              if (hasChat) ...[
                const SizedBox(width: 12),
                _ChatOrb(active: active == 4, onTap: () => _onTap(context, 4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating Chat button next to the nav bar: blue→green gradient orb
/// with a soft glow, a bot icon and a green "online" dot; a white ring
/// while you're in Chat.
class _ChatOrb extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _ChatOrb({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Chat',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand, AppColors.positive],
            ),
            border: Border.all(
              color: active ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.positive.withValues(alpha: active ? 0.6 : 0.4),
                blurRadius: active ? 22 : 16,
                offset: const Offset(0, 6),
              ),
            ]),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                active ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                color: Colors.white,
                size: 26,
              ),
              // "Online" dot.
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.positive,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
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
