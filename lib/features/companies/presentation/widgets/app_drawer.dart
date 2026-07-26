import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_logo.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 260,
      backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: logo + close ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const BrixenLogo(size: 40, animate: false),
                  const SizedBox(width: 10),
                  Text(
                    'BRIXEN',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Theme.of(context).dividerColor, height: 1),

            // ── Profile ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('AD',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.silver)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Super Admin',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: Theme.of(context).dividerColor, height: 1),
            const SizedBox(height: 6),

            // ── Nav Items ──────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _DrawerItem(icon: Icons.business_outlined, label: 'Companies', isActive: currentRoute == AppRouter.companies, onTap: () { Navigator.pop(context); context.go(AppRouter.companies); }),
                  _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Sales', isActive: currentRoute == AppRouter.sales, onTap: () { Navigator.pop(context); context.go(AppRouter.sales); }),
                  _DrawerItem(icon: Icons.people_outline, label: 'Users', isActive: false, onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.card_membership_outlined, label: 'Subscriptions', isActive: false, onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.person_outline, label: 'Persons', isActive: false, onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.track_changes_outlined, label: 'Activity Log', isActive: false, onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', isActive: false, onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.lock_outline, label: 'App Lock', isActive: currentRoute == AppRouter.security, onTap: () { Navigator.pop(context); context.push(AppRouter.security); }),
                  _DrawerItem(icon: Icons.help_outline, label: 'Support', isActive: false, onTap: () => Navigator.pop(context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(color: Theme.of(context).dividerColor, height: 20),
                  ),
                  _DrawerItem(icon: Icons.logout, label: 'Logout', isActive: false, isDestructive: true, onTap: () { Navigator.pop(context); context.go(AppRouter.signIn); }),
                ],
              ),
            ),

            // ── Theme Toggle ───────────────────────────────
            Divider(color: Theme.of(context).dividerColor, height: 1),
            _ThemeToggle(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isActive
            ? AppColors.silver
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.silver.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? const Border(left: BorderSide(color: AppColors.silver, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined,
                  size: 15,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : AppColors.silver),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => themeCubit.toggle(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 42,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.silver.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.silverDark),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                          color: AppColors.silver, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.dark_mode_outlined,
                  size: 15,
                  color: isDark
                      ? AppColors.silver
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const Spacer(),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
