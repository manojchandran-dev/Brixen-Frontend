import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_logo.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  const AppSidebar({super.key, required this.currentRoute});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _expanded = true;

  static const double _expandedW = 155;
  static const double _collapsedW = 56;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: _expanded ? _expandedW : _collapsedW,
      color: bg,
      child: SafeArea(
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Toggle + Logo row ──────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _expanded ? 10 : 8, vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _expanded ? Icons.menu_open : Icons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(width: 8),
                      const BrixenLogo(size: 36, animate: false),
                    ],
                  ],
                ),
              ),

              // ── Profile ────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _ProfileFull(),
                secondChild: _ProfileIcon(),
              ),

              Divider(
                  color: Theme.of(context).dividerColor,
                  height: 1,
                  indent: 8,
                  endIndent: 8),
              const SizedBox(height: 4),

              // ── Nav items ──────────────────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Item(icon: Icons.business_outlined, label: 'Companies', isActive: widget.currentRoute == AppRouter.companies, expanded: _expanded, onTap: () => context.go(AppRouter.companies)),
                    _Item(icon: Icons.receipt_long_outlined, label: 'Sales', isActive: widget.currentRoute == AppRouter.sales, expanded: _expanded, onTap: () => context.go(AppRouter.sales)),
                    _Item(icon: Icons.people_outline_rounded, label: 'Customers', isActive: widget.currentRoute == AppRouter.customers, expanded: _expanded, onTap: () => context.go(AppRouter.customers)),
                    _Item(icon: Icons.people_outline, label: 'Users', isActive: false, expanded: _expanded, onTap: () {}),
                    _Item(icon: Icons.card_membership_outlined, label: 'Subscriptions', isActive: false, expanded: _expanded, onTap: () {}),
                    _Item(icon: Icons.person_outline, label: 'Persons', isActive: false, expanded: _expanded, onTap: () {}),
                    _Item(icon: Icons.track_changes_outlined, label: 'Activity Log', isActive: false, expanded: _expanded, onTap: () {}),
                    _Item(icon: Icons.settings_outlined, label: 'Settings', isActive: false, expanded: _expanded, onTap: () {}),
                    _Item(icon: Icons.help_outline, label: 'Support', isActive: false, expanded: _expanded, onTap: () {}),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(color: Theme.of(context).dividerColor, height: 16),
                    ),
                    _Item(icon: Icons.logout, label: 'Logout', isActive: false, expanded: _expanded, isDestructive: true, onTap: () => context.go(AppRouter.signIn)),
                  ],
                ),
              ),

              // ── Theme toggle ───────────────────────────────
              Divider(color: Theme.of(context).dividerColor, height: 1),
              _ThemeBar(expanded: _expanded),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile widgets ──────────────────────────────────────────────────────────

class _ProfileFull extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          _Avatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                Text('Super Admin',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(child: _Avatar()),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('AD',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.silver)),
      ),
    );
  }
}

// ── Nav item ─────────────────────────────────────────────────────────────────

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;
  final bool isDestructive;

  const _Item({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expanded,
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

    return Tooltip(
      message: expanded ? '' : label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: expanded ? 10 : 0, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.silver.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive && expanded
                ? const Border(
                    left: BorderSide(color: AppColors.silver, width: 2.5))
                : null,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(icon, size: 17, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(child: Icon(icon, size: 18, color: color)),
        ),
      ),
    );
  }
}

// ── Theme toggle bar ─────────────────────────────────────────────────────────

class _ThemeBar extends StatelessWidget {
  final bool expanded;
  const _ThemeBar({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        final toggle = GestureDetector(
          onTap: () => themeCubit.toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 34,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.silver.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.silverDark),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                    color: AppColors.silver, shape: BoxShape.circle),
              ),
            ),
          ),
        );

        if (!expanded) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: GestureDetector(
                onTap: () => themeCubit.toggle(),
                child: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wb_sunny_outlined,
                  size: 13,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : AppColors.silver),
              const SizedBox(width: 6),
              toggle,
              const SizedBox(width: 6),
              Icon(Icons.dark_mode_outlined,
                  size: 13,
                  color: isDark
                      ? AppColors.silver
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }
}
