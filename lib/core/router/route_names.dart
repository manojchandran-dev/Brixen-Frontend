/// Every route path string in the app, centralized here.
///
/// Signed-in pages are nested under /dashboard (and create/detail pages
/// under their list) so go_router builds a real back stack from the path:
/// `go(createEmployee)` = Dashboard → Employees → Create. One back/swipe =
/// one page up; only the Dashboard itself exits the app. [AppRouter] exposes
/// identically-named constants that delegate to these — existing call sites
/// keep using `AppRouter.xxx` unchanged.
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/dashboard/profile';
  static const String changePassword = '/dashboard/profile/change-password';
  static const String companies = '/dashboard/companies';
  static const String createCompany = '/dashboard/companies/create';
  static const String dashboard = '/dashboard';
  static const String report = '/dashboard/reports';
  static const String more = '/dashboard/more';
  static const String sales = '/dashboard/sales';
  static const String createSale = '/dashboard/sales/create';
  static const String customers = '/dashboard/customers';
  static const String createCustomer = '/dashboard/customers/create';
  static const String purchases = '/dashboard/purchases';
  static const String createPurchase = '/dashboard/purchases/create';
  static const String expenses = '/dashboard/expenses';
  static const String createExpense = '/dashboard/expenses/create';
  static const String employees = '/dashboard/employees';
  static const String createEmployee = '/dashboard/employees/create';
  static const String products = '/dashboard/products';
  static const String createProduct = '/dashboard/products/create';
  static const String permissions = '/dashboard/permissions';
  static const String createPermission = '/dashboard/permissions/create';
  static const String moduleAccess = '/dashboard/permissions/module';
  static const String pushNotifications = '/dashboard/notifications/push';
  static const String createPushNotification =
      '/dashboard/notifications/push/create';
  static const String announcements = '/dashboard/notifications/announcements';
  static const String createAnnouncement =
      '/dashboard/notifications/announcements/create';
  static const String support = '/dashboard/support';
  static const String createTicket = '/dashboard/support/create';
  static const String ticketDetail = '/dashboard/support/ticket';
  static const String chat = '/dashboard/chat';
  static const String chatRoom = '/dashboard/chat/room';
  static const String masterCompanyCategories =
      '/dashboard/masters/company-categories';
  static const String masterExpenseCategories =
      '/dashboard/masters/expense-categories';
  static const String masterProductCategories =
      '/dashboard/masters/product-categories';
  static const String masterUnits = '/dashboard/masters/units';
  static const String lockScreen = '/lock';
  static const String security = '/dashboard/security';
  static const String setPin = '/dashboard/security/set-pin';
  static const String pinSetup = '/security/pin-setup';
}
