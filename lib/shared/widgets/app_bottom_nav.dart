import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  const AppBottomNav({super.key, required this.activeIndex});

  void _onTap(BuildContext context, int index) {
    if (index == activeIndex) return;
    switch (index) {
      case 0:
      case 1:
      case 2:
      case 3:
        context.go(AppRouter.companies);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavBtn(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded,           label: 'Dashboard',  isActive: activeIndex == 0, onTap: () => _onTap(context, 0)),
                _NavBtn(icon: Icons.access_time_outlined,  activeIcon: Icons.access_time_filled_rounded,  label: 'Attendance', isActive: activeIndex == 1, onTap: () => _onTap(context, 1)),
                _NavBtn(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart_rounded,           label: 'Report',     isActive: activeIndex == 2, onTap: () => _onTap(context, 2)),
                _NavBtn(icon: Icons.grid_view_outlined,    activeIcon: Icons.grid_view_rounded,           label: 'Menu',       isActive: activeIndex == 3, onTap: () => _onTap(context, 3)),
              ],
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.textSecondary : AppColors.lightTextHint;
    final activePillColor = isDark ? null : AppColors.lightTextPrimary;
    final activeContentColor = isDark ? AppColors.black : AppColors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: (isActive && isDark) ? AppColors.silverGradient : null,
            color: isActive ? activePillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark
                          ? AppColors.silver.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? activeContentColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeContentColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
