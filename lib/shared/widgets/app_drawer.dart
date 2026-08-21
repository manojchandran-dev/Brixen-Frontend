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
      color: AppColors.ink,
      onTap: (context) => context.go(AppRouter.expenses),
    ),
  ];

  static final List<_DrawerItem> _masterItems = [
    _DrawerItem(
      icon: Icons.apartment_rounded,
      label: 'Company Category',
      subtitle: 'Company types',
      color: AppColors.brand,
      onTap: (context) => context.go(AppRouter.companies, extra: 'masters/companyCategory'),
    ),
    _DrawerItem(
      icon: Icons.sell_rounded,
      label: 'Expense Category',
      subtitle: 'Spending types',
      color: AppColors.positive,
      onTap: (context) => context.go(AppRouter.companies, extra: 'masters/expenseCategory'),
    ),
    _DrawerItem(
      icon: Icons.straighten_rounded,
      label: 'Units',
      subtitle: 'Measurement units',
      color: AppColors.brandDeep,
      onTap: (context) => context.go(AppRouter.companies, extra: 'masters/unit'),
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
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/images/icon.png', width: 32, height: 32, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Brix', style: TextStyle(color: AppColors.brand)),
                      const TextSpan(text: 'en', style: TextStyle(color: AppColors.positive)),
                    ]),
                    style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Text('Jump to a module', style: TextStyle(color: AppColors.textHint, fontSize: 12.5)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _moduleItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.98,
                    ),
                    itemBuilder: (_, i) => _DrawerTile(item: _moduleItems[i]),
                  ),
                  const SizedBox(height: 26),
                  Row(children: [
                    Container(
                      width: 30, height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandDeep, AppColors.ink]),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [BoxShadow(color: AppColors.brandDeep.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, size: 15, color: AppColors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text('Masters', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
                  const Padding(
                    padding: EdgeInsets.only(left: 40, top: 2),
                    child: Text('Categories & units', style: TextStyle(color: AppColors.textHint, fontSize: 11.5)),
                  ),
                  const SizedBox(height: 12),
                  ..._masterItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MasterRowTile(item: item),
                      )),
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
    // Same pale opaque-tint + colored hard-edge treatment used on every
    // list card app-wide, so each module reads as its own accent color
    // instead of a flat white box.
    final bg = Color.lerp(AppColors.surface, item.color, 0.32)!;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        item.onTap(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            right: BorderSide(color: item.color, width: 2.5),
            bottom: BorderSide(color: item.color, width: 5),
          ),
          boxShadow: [
            BoxShadow(color: item.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(2, 6)),
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10)),
            BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 8, offset: const Offset(-4, -4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.color, item.color.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: item.color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Icon(item.icon, size: 22, color: AppColors.white),
            ),
            const Spacer(),
            Text(item.label, style: const TextStyle(color: AppColors.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(item.subtitle, style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6), fontSize: 11)),
          ],
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        item.onTap(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
            BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.color, item.color.withValues(alpha: 0.75)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: item.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(item.icon, size: 18, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(item.subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
            ),
          ],
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
