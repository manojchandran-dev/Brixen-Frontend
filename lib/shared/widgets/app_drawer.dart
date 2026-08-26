import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// Slide-out navigation drawer used across module pages (Employees, Sales,
/// Customers, Expenses, Purchases, Companies) — opened via the hamburger
/// icon in the AppBar. Shows modules only — profile, theme and settings
/// live in the "More" bottom-nav tab instead.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static final List<_DrawerItem> _moduleItems = [
    _DrawerItem(
      icon: Icons.business_rounded,
      label: 'Companies',
      subtitle: 'All companies',
      color: AppColors.brand,
      onTap: (context) => context.go(AppRouter.companies, extra: 'companies'),
    ),
    _DrawerItem(
      icon: Icons.badge_rounded,
      label: 'Employees',
      subtitle: 'Manage staff',
      color: AppColors.positive,
      onTap: (context) => context.go(AppRouter.employees),
    ),
    _DrawerItem(
      icon: Icons.receipt_long_rounded,
      label: 'Sales',
      subtitle: 'Invoices',
      color: AppColors.brandDeep,
      onTap: (context) => context.go(AppRouter.sales),
    ),
    _DrawerItem(
      icon: Icons.people_alt_rounded,
      label: 'Customers',
      subtitle: 'Customer records',
      color: AppColors.brandLight,
      onTap: (context) => context.go(AppRouter.customers),
    ),
    _DrawerItem(
      icon: Icons.receipt_outlined,
      label: 'Expenses',
      subtitle: 'Track spending',
      color: AppColors.brandBlack,
      onTap: (context) => context.go(AppRouter.expenses),
    ),
  ];

  static final List<_DrawerItem> _masterItems = [
    _DrawerItem(
      icon: Icons.apartment_rounded,
      label: 'Company Category',
      subtitle: 'Company types',
      color: AppColors.brand,
      onTap: (context) =>
          context.go(AppRouter.companies, extra: 'masters/companyCategory'),
    ),
    _DrawerItem(
      icon: Icons.sell_rounded,
      label: 'Expense Category',
      subtitle: 'Spending types',
      color: AppColors.positive,
      onTap: (context) =>
          context.go(AppRouter.companies, extra: 'masters/expenseCategory'),
    ),
    _DrawerItem(
      icon: Icons.straighten_rounded,
      label: 'Units',
      subtitle: 'Measurement units',
      color: AppColors.brandDeep,
      onTap: (context) =>
          context.go(AppRouter.companies, extra: 'masters/unit'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.of(context).size.width * 0.86,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brand.withValues(alpha: 0.14),
                          AppColors.positive.withValues(alpha: 0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.highlightShadow(0.9),
                          blurRadius: 6,
                          offset: const Offset(-3, -3),
                        ),
                      ]),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Brix',
                          style: TextStyle(color: AppColors.brand),
                        ),
                        const TextSpan(
                          text: 'en',
                          style: TextStyle(color: AppColors.positive),
                        ),
                      ],
                    ),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: Text(
                'Jump to a module',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(height: 1, color: AppColors.border),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  ..._moduleItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DrawerTile(item: item),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.dashboard_customize_rounded,
                          size: 14,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Masters',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(height: 1, color: AppColors.border),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 38, top: 3),
                    child: Text(
                      'Categories & units',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._masterItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _MasterRowTile(item: item),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  const _DrawerTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        item.onTap(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: AppColors.highlightShadow(0.9),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.accentGradient(item.color),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.accentGradient(item.color),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.shadows([
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]),
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textHint.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MasterRowTile extends StatelessWidget {
  final _DrawerItem item;
  const _MasterRowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // Same white-card + left-accent language as the modules above, kept
    // deliberately quieter (smaller icon, thinner accent, indented) so the
    // hierarchy — nested under "Masters" — still reads at a glance.
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        item.onTap(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: AppColors.highlightShadow(0.85),
              blurRadius: 6,
              offset: const Offset(-3, -3),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.accentGradient(item.color),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.accentGradient(item.color),
                            ),
                            shape: BoxShape.circle,
                            boxShadow: AppColors.shadows([
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.28),
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ]),
                          ),
                          child: Icon(
                            item.icon,
                            size: 15,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textHint.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final void Function(BuildContext context) onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
