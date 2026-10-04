import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/session_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/datasources/profile_remote_datasource.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/companies/presentation/providers/companies_provider.dart';
import 'features/customers/presentation/providers/customers_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/employees/presentation/providers/employees_provider.dart';
import 'features/expenses/presentation/providers/expenses_provider.dart';
import 'features/notifications/presentation/providers/announcements_provider.dart';
import 'features/notifications/presentation/providers/inbox_provider.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/notifications/presentation/providers/push_notifications_provider.dart';
import 'features/permissions/presentation/providers/permissions_provider.dart';
import 'features/products/presentation/providers/products_provider.dart';
import 'features/purchases/presentation/providers/purchases_provider.dart';
import 'features/reports/presentation/superadmin/superadmin_reports_data.dart';
import 'features/sales/presentation/providers/sales_provider.dart';
import 'features/support/presentation/providers/support_tickets_provider.dart';

/// The server data a page shows, by its exact path — refreshed when you
/// land on that page (see [_BrixenAppState._onRoute]). Only this page's
/// data: pages still mounted underneath (the dashboard is under every
/// module) keep theirs until you go back to them, and create/edit forms
/// refresh nothing.
List<ProviderOrFamily> _dataFor(String path) {
  final superAdmin = Session.isSuperAdmin;
  return switch (path) {
    RouteNames.dashboard =>
      superAdmin
          ? [superadminDashboardProvider]
          : [
              dashboardSummaryProvider,
              salesProvider,
              expensesProvider,
              customersProvider,
              employeesProvider,
              productsProvider,
              inboxProvider,
            ],
    RouteNames.report =>
      superAdmin
          ? [superadminReportProvider]
          : [
              salesProvider,
              expensesProvider,
              customersProvider,
              employeesProvider,
              productsProvider,
            ],
    RouteNames.companies => [companiesProvider, companyResultsProvider],
    RouteNames.permissions => [
      permissionCompaniesProvider,
      permissionsProvider,
    ],
    RouteNames.sales => [salesProvider],
    RouteNames.customers => [customersProvider],
    RouteNames.expenses => [expensesProvider],
    RouteNames.employees => [employeesProvider],
    RouteNames.products => [productsProvider],
    RouteNames.inventory => [inventoryProvider],
    RouteNames.purchases => [purchasesProvider],
    RouteNames.pushNotifications => [pushNotificationsProvider],
    RouteNames.announcements => [announcementsProvider],
    RouteNames.support => [supportTicketsProvider],
    RouteNames.chat => [chatConversationsProvider],
    RouteNames.profile || RouteNames.more => [profileProvider],
    _ => const [],
  };
}

class BrixenApp extends ConsumerStatefulWidget {
  const BrixenApp({super.key});

  @override
  ConsumerState<BrixenApp> createState() => _BrixenAppState();
}

class _BrixenAppState extends ConsumerState<BrixenApp> {
  late final StreamSubscription<ThemeMode> _themeSub;
  String? _lastPath;

  /// Every page change (go, push or back) → refetch that page's data (see
  /// [_dataFor]). The page keeps its old data visible until the new data
  /// arrives.
  void _onRoute() {
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (path == _lastPath) return;
    _lastPath = path;
    // After the frame: the router notifies mid-navigation, and providers
    // can't be invalidated while widgets are building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final p in _dataFor(path)) {
        ref.invalidate(p);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(_onRoute);
    _themeSub = themeCubit.stream.listen((_) {
      if (!mounted) return;
      // Widgets that read AppColors getters directly (not Theme.of) don't
      // depend on the theme, so Flutter won't rebuild them on a toggle —
      // they'd keep light colours in dark mode. Mark the whole tree dirty.
      AppColors.setBrightness(
        themeCubit.isDark ? Brightness.dark : Brightness.light,
      );
      void rebuild(Element e) {
        e.markNeedsBuild();
        e.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
      setState(() {});
    });
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRoute);
    _themeSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppColors' surface/text tokens are runtime getters, not consts, so
    // they need this set before anything below reads them this frame.
    AppColors.setBrightness(
      themeCubit.isDark ? Brightness.dark : Brightness.light,
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeCubit.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
    return MaterialApp.router(
      title: 'Brixen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCubit.state,
      routerConfig: AppRouter.router,
    );
  }
}
