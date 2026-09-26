import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../features/navigation/domain/entities/nav_module.dart';
import '../../features/navigation/presentation/module_visuals.dart';
import '../../features/navigation/presentation/providers/nav_modules_provider.dart';
import 'error_state.dart';
import 'skeleton.dart';

/// Company users open Support from the More page, so it's left out of
/// their menu. Superadmin keeps it here (their More page doesn't have it).
bool _supportInMore(NavModule m) =>
    !Session.isSuperAdmin &&
    m.name.toLowerCase().replaceAll(RegExp(r's+'), '').startsWith('support');

/// Slide-out navigation drawer used across module pages (Employees, Sales,
/// Customers, Expenses, Purchases, Companies) — opened via the hamburger
/// icon in the AppBar. Shows modules only — profile, theme and settings
/// live in the "More" bottom-nav tab instead.
///
/// The menu itself (which modules exist, their names/descriptions, and the
/// Masters group's children) comes from `GET /api/v1/modules` — nothing
/// here is a hardcoded list. Icons/colours/routes aren't part of that API
/// (it's pure navigation metadata), so [_visualFor] maps a module's name to
/// a look + destination on the client, with a generic fallback for any
/// module name it doesn't recognise.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(navModulesProvider);

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
                    style: const TextStyle(
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
              child: modulesAsync.when(
                loading: () => const SkeletonDrawerMenu(),
                error: (e, _) => ErrorCard(
                  error: e,
                  onRetry: () => ref.invalidate(navModulesProvider),
                ),
                data: (modules) => ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    // Groups (Masters) always last, whatever order the API returns.
                    for (final m in [
                      ...modules.where(
                        (m) => m.children.isEmpty && !_supportInMore(m),
                      ),
                      ...modules.where((m) => m.children.isNotEmpty),
                    ])
                      if (m.children.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DrawerTile(module: m),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 14),
                          child: _GroupSection(module: m),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a menu entry navigates to, keyed by the module's name — the API
/// only carries id/name/description/parent_id/children, no route info.
/// Icon/colour come from the shared [moduleVisualFor] instead of being
/// duplicated here.
void Function(BuildContext context) _destinationFor(NavModule module) {
  final key = module.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  switch (key) {
    case 'companies':
      return (context) => context.go(
        AppRouter.companies,
        extra: AppRouter.companiesSection('companies'),
      );
    case 'permissions':
      return (context) => context.go(AppRouter.permissions);
    case 'employees':
      return (context) => context.go(AppRouter.employees);
    case 'sales':
      return (context) => context.go(AppRouter.sales);
    case 'purchases':
      return (context) => context.go(AppRouter.purchases);
    case 'customers':
      return (context) => context.go(AppRouter.customers);
    case 'expenses':
      return (context) => context.go(AppRouter.expenses);
    case 'products':
      return (context) => context.go(AppRouter.products);
    case 'companycategory':
      return (context) => context.go(
        AppRouter.companies,
        extra: AppRouter.companiesSection('masters/companyCategory'),
      );
    case 'expensecategory':
      return (context) => context.go(
        AppRouter.companies,
        extra: AppRouter.companiesSection('masters/expenseCategory'),
      );
    case 'units':
    case 'unit':
      return (context) => context.go(
        AppRouter.companies,
        extra: AppRouter.companiesSection('masters/unit'),
      );
    case 'productcategory':
      return (context) => context.go(
        AppRouter.companies,
        extra: AppRouter.companiesSection('masters/productCategory'),
      );
    // No backend module row exists for these yet — the module only reaches
    // superAdmin today via the Dashboard's Quick Actions tiles
    // (welcome_dashboard_view.dart). These cases are additive/forward-
    // compat: the moment backend registers a "Notifications"/"Push
    // Notifications"/"Announcements" module, this drawer entry works with
    // no further client changes.
    case 'notifications':
    case 'pushnotifications':
      return (context) => context.go(AppRouter.pushNotifications);
    case 'announcements':
      return (context) => context.go(AppRouter.announcements);
    case 'chat':
    case 'chatbot':
      return (context) => context.go(AppRouter.chat);
    case 'support':
    case 'supportticket':
    case 'supporttickets':
      return (context) => context.go(AppRouter.support);
    default:
      // Any module the app doesn't have a screen for yet — shown, but
      // inert, rather than silently dropped or crashing on an unknown key.
      return (context) {};
  }
}

class _DrawerTile extends StatelessWidget {
  final NavModule module;
  const _DrawerTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final visual = moduleVisualFor(module.name);
    final destination = _destinationFor(module);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        destination(context);
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
                      colors: AppColors.accentGradient(visual.color),
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
                              colors: AppColors.accentGradient(visual.color),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.shadows([
                              BoxShadow(
                                color: visual.color.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]),
                          ),
                          child: Icon(
                            visual.icon,
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
                                module.name,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                module.description ?? '',
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

/// A module that carries children (e.g. "Masters") — rendered as a section
/// header followed by its children as [_MasterRowTile]s.
class _GroupSection extends StatelessWidget {
  final NavModule module;
  const _GroupSection({required this.module});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              module.name,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.border)),
          ],
        ),
        if (module.description != null && module.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 3),
            child: Text(
              module.description!,
              style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
            ),
          ),
        const SizedBox(height: 14),
        for (final child in module.children)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _MasterRowTile(module: child),
          ),
      ],
    );
  }
}

class _MasterRowTile extends StatelessWidget {
  final NavModule module;
  const _MasterRowTile({required this.module});

  @override
  Widget build(BuildContext context) {
    // Same white-card + left-accent language as the modules above, kept
    // deliberately quieter (smaller icon, thinner accent, indented) so the
    // hierarchy — nested under "Masters" — still reads at a glance.
    final visual = moduleVisualFor(module.name);
    final destination = _destinationFor(module);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        destination(context);
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
                      colors: AppColors.accentGradient(visual.color),
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
                              colors: AppColors.accentGradient(visual.color),
                            ),
                            shape: BoxShape.circle,
                            boxShadow: AppColors.shadows([
                              BoxShadow(
                                color: visual.color.withValues(alpha: 0.28),
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ]),
                          ),
                          child: Icon(
                            visual.icon,
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
                                module.name,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                module.description ?? '',
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
