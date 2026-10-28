import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/permissions/presentation/providers/module_access_provider.dart';
import 'pill_segmented_control.dart';

/// Screens that share one menu entry, switched with [ModuleTabs]:
///   staff — Employees · Salary (Staff Permissions opens from Employees)
///   money — Expenses · Purchases
///   stock — Products · Inventory
enum ModuleGroup { staff, money, stock }

List<PillSegment<String>> _tabsFor(ModuleGroup group, WidgetRef ref) =>
    switch (group) {
      ModuleGroup.staff => const [
        PillSegment(
          value: AppRouter.employees,
          label: 'Employees',
          icon: Icons.badge_outlined,
        ),
        PillSegment(
          value: AppRouter.salaryGeneration,
          label: 'Salary',
          icon: Icons.payments_outlined,
        ),
      ],
      ModuleGroup.money => [
        if (ref.watch(moduleAccessProvider('Expenses')).view)
          const PillSegment(
            value: AppRouter.expenses,
            label: 'Expenses',
            icon: Icons.receipt_long_outlined,
          ),
        if (ref.watch(moduleAccessProvider('Purchases')).view)
          const PillSegment(
            value: AppRouter.purchases,
            label: 'Purchases',
            icon: Icons.shopping_cart_outlined,
          ),
      ],
      ModuleGroup.stock => const [
        PillSegment(
          value: AppRouter.products,
          label: 'Products',
          icon: Icons.checkroom_outlined,
        ),
        PillSegment(
          value: AppRouter.inventory,
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
        ),
      ],
    };

/// The tab bar under a grouped screen's title — the same two-way switch as
/// Sales' GST / Secondary bills, one segment per screen of the [group] the
/// user may open, [current] lit. Switching opens the other screen in place,
/// without a slide (those routes use no transition).
class ModuleTabs extends ConsumerWidget implements PreferredSizeWidget {
  final ModuleGroup group;

  /// The route of the screen showing this bar.
  final String current;
  const ModuleTabs({super.key, required this.group, required this.current});

  static const height = 62.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = _tabsFor(group, ref);
    if (tabs.length < 2) {
      return Container(height: 1, color: AppColors.border);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: PillSegmentedControl<String>(
        value: current,
        onChanged: (route) {
          if (route != current) context.go(route);
        },
        segments: tabs,
      ),
    );
  }
}
