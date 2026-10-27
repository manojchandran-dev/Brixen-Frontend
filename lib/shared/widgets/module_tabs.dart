import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/permissions/presentation/providers/module_access_provider.dart';

/// Screens that share one menu entry, switched with [ModuleTabs]:
///   staff — Employees · Staff Permissions · Salary
///   money — Expenses · Purchases
///   stock — Products · Inventory
enum ModuleGroup { staff, money, stock }

typedef _Tab = ({String label, IconData icon, String route});

List<_Tab> _tabsFor(ModuleGroup group, WidgetRef ref) => switch (group) {
  ModuleGroup.staff => [
    (label: 'Employees', icon: Icons.badge_rounded, route: AppRouter.employees),
    // Company admins only: employee logins never manage access.
    if (Session.role == UserRole.companyAdmin)
      (
        label: 'Permissions',
        icon: Icons.admin_panel_settings_rounded,
        route: AppRouter.staffPermissions,
      ),
    (
      label: 'Salary',
      icon: Icons.payments_rounded,
      route: AppRouter.salaryGeneration,
    ),
  ],
  ModuleGroup.money => [
    if (ref.watch(moduleAccessProvider('Expenses')).view)
      (
        label: 'Expenses',
        icon: Icons.receipt_long_rounded,
        route: AppRouter.expenses,
      ),
    if (ref.watch(moduleAccessProvider('Purchases')).view)
      (
        label: 'Purchases',
        icon: Icons.shopping_cart_rounded,
        route: AppRouter.purchases,
      ),
  ],
  ModuleGroup.stock => [
    (
      label: 'Products',
      icon: Icons.checkroom_rounded,
      route: AppRouter.products,
    ),
    (
      label: 'Inventory',
      icon: Icons.inventory_2_rounded,
      route: AppRouter.inventory,
    ),
  ],
};

/// The tab row under a grouped screen's title: one pill per screen of the
/// [group] the user may open, [current] lit. Tapping another opens it in
/// place (same menu entry, same back stack).
class ModuleTabs extends ConsumerWidget implements PreferredSizeWidget {
  final ModuleGroup group;

  /// The route of the screen showing this row.
  final String current;
  const ModuleTabs({super.key, required this.group, required this.current});

  static const height = 54.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = _tabsFor(group, ref);
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                tab: t,
                selected: t.route == current,
                onTap: t.route == current ? null : () => context.go(t.route),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback? onTap;
  const _Pill({required this.tab, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDeep],
              )
            : null,
        color: selected ? null : AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.brand.withValues(alpha: 0.18),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab.icon,
            size: 16,
            color: selected ? Colors.white : AppColors.brand,
          ),
          const SizedBox(width: 6),
          Text(
            tab.label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
