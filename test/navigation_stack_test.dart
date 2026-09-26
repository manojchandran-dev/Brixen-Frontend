import 'package:brixen/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pages go_router stacks for [location] — what back/swipe walks through.
List<String> _stack(String location) => AppRouter.router.configuration
    .findMatch(Uri.parse(location))
    .matches
    .map((m) => m.matchedLocation)
    .toList();

void main() {
  test('Add Company sits on Companies, which sits on the Dashboard', () {
    expect(_stack(AppRouter.createCompany), [
      AppRouter.dashboard,
      AppRouter.companies,
      AppRouter.createCompany,
    ]);
  });

  test('every module list is one step above the Dashboard', () {
    for (final list in [
      AppRouter.companies, AppRouter.employees, AppRouter.products,
      AppRouter.customers, AppRouter.sales, AppRouter.purchases,
      AppRouter.expenses, AppRouter.permissions, AppRouter.pushNotifications,
      AppRouter.announcements, AppRouter.support, AppRouter.chat,
      AppRouter.masterCompanyCategories, AppRouter.masterUnits,
      AppRouter.security, AppRouter.report, AppRouter.more,
    ]) {
      expect(_stack(list), [AppRouter.dashboard, list], reason: list);
    }
  });

  test('create/detail pages sit on their list', () {
    final pairs = {
      AppRouter.createEmployee: AppRouter.employees,
      AppRouter.createProduct: AppRouter.products,
      AppRouter.createCustomer: AppRouter.customers,
      AppRouter.createSale: AppRouter.sales,
      AppRouter.createPurchase: AppRouter.purchases,
      AppRouter.createExpense: AppRouter.expenses,
      AppRouter.createPermission: AppRouter.permissions,
      AppRouter.ticketDetail: AppRouter.support,
      AppRouter.setPin: AppRouter.security,
      AppRouter.changePassword: AppRouter.profile,
    };
    pairs.forEach((child, parent) {
      expect(_stack(child), [AppRouter.dashboard, parent, child], reason: child);
    });
  });

  test('the Dashboard is a root (back there = exit prompt)', () {
    expect(_stack(AppRouter.dashboard), [AppRouter.dashboard]);
    expect(_stack(AppRouter.signIn), [AppRouter.signIn]);
  });
}
