/// Every route path string in the app, centralized here. [AppRouter] exposes
/// identically-named constants that delegate to these — existing call sites
/// keep using `AppRouter.xxx` unchanged.
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String companies = '/companies';
  static const String createCompany = '/companies/create';
  static const String dashboard = '/dashboard';
  static const String report = '/reports';
  static const String more = '/more';
  static const String sales = '/sales';
  static const String createSale = '/sales/create';
  static const String customers = '/customers';
  static const String createCustomer = '/customers/create';
  static const String purchases = '/purchases';
  static const String createPurchase = '/purchases/create';
  static const String expenses = '/expenses';
  static const String createExpense = '/expenses/create';
  static const String employees = '/employees';
  static const String createEmployee = '/employees/create';
  static const String products = '/products';
  static const String createProduct = '/products/create';
  static const String permissions = '/permissions';
  static const String createPermission = '/permissions/create';
  static const String moduleAccess = '/permissions/module';
  static const String pushNotifications = '/notifications/push';
  static const String createPushNotification = '/notifications/push/create';
  static const String announcements = '/notifications/announcements';
  static const String createAnnouncement = '/notifications/announcements/create';
  static const String support = '/support';
  static const String createTicket = '/support/create';
  static const String ticketDetail = '/support/ticket';
  static const String chat = '/chat';
  static const String chatRoom = '/chat/room';
  static const String masterCompanyCategories = '/masters/company-categories';
  static const String masterExpenseCategories = '/masters/expense-categories';
  static const String masterProductCategories = '/masters/product-categories';
  static const String masterUnits = '/masters/units';
  static const String lockScreen = '/lock';
  static const String security = '/security';
  static const String setPin = '/security/set-pin';
  static const String pinSetup = '/security/pin-setup';
}
