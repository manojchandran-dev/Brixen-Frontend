import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = AppConfig.baseUrl;

  static const String health = '/api/health';
  static const String login = '/api/v1/auth/login';
  static const String authPin = '/api/v1/auth/pin';
  static const String authPinVerify = '/api/v1/auth/pin/verify';

  /// Forgot PIN: email an OTP → verify it (reset token) → set a new PIN.
  static const String authPinForgot = '/api/v1/auth/pin/forgot';
  static const String authPinForgotVerify = '/api/v1/auth/pin/forgot/verify';
  static const String authPinReset = '/api/v1/auth/pin/reset';
  static const String forgotPassword = '/api/v1/auth/forgot-password';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String resetPassword = '/api/v1/auth/reset-password';
  // Logged-in change-password — distinct from resetPassword (pre-login,
  // OTP-verified). Sends the Bearer token instead of a reset token.
  static const String changePassword = '/api/v1/auth/change-password';
  static const String me = '/api/v1/auth/me';
  static const String companies = '/api/v1/companies';
  static const String expenseCategories = '/api/v1/expense-categories';
  static const String companyCategories = '/api/v1/company-categories';
  static const String productCategories = '/api/v1/product-categories';
  static const String employees = '/api/v1/employees';
  static const String units = '/api/v1/units';
  static const String expenses = '/api/v1/expenses';
  static const String customers = '/api/v1/customers';
  static const String sales = '/api/v1/sales';
  static const String products = '/api/v1/products';
  static const String dashboardSummary = '/api/v1/dashboard/summary';

  /// Superadmin dashboard: every count, recent activity and health in one call.
  static const String superadminDashboard = '/api/v1/dashboard/superadmin';
  static const String reportsSummary = '/api/v1/reports/summary';

  /// Superadmin report tab: append company | users | notifications | support | chatbot | activity.
  static const String superadminReports = '/api/v1/reports/superadmin';
  static const String modules = '/api/v1/modules';
  static const String uploads = '/api/v1/uploads';
  static const String pushNotifications = '/api/v1/notifications/push';
  static const String pushDevices = '/api/v1/notifications/push/devices';
  static String pushNotificationById(String id) =>
      '/api/v1/notifications/push/$id';
  static String pushNotificationDuplicate(String id) =>
      '/api/v1/notifications/push/$id/duplicate';
  static String pushNotificationCancel(String id) =>
      '/api/v1/notifications/push/$id/cancel';
  static const String announcements = '/api/v1/announcements';
  static String announcementById(String id) => '/api/v1/announcements/$id';
  static String announcementDuplicate(String id) =>
      '/api/v1/announcements/$id/duplicate';
  static String announcementUnpublish(String id) =>
      '/api/v1/announcements/$id/unpublish';
  static const String supportTickets = '/api/v1/support/tickets';
  static String supportTicketById(String id) => '/api/v1/support/tickets/$id';
  static String supportTicketStatus(String id) =>
      '/api/v1/support/tickets/$id/status';
  static String supportTicketAssign(String id) =>
      '/api/v1/support/tickets/$id/assign';
  static String supportTicketMessages(String id) =>
      '/api/v1/support/tickets/$id/messages';
  static const String chatConversations = '/api/v1/chat/conversations';
  static String chatMessages(String companyId) =>
      '/api/v1/chat/conversations/$companyId/messages';
  static const String permissions = '/api/v1/permissions';
  static const String permissionsBulk = '/api/v1/permissions/bulk';

  /// Companies list for the Permissions screen, each with its access counts.
  static const String permissionCompanies = '/api/v1/permissions/companies';
  static String permissionById(String id) => '/api/v1/permissions/$id';

  static String companyById(String id) => '/api/v1/companies/$id';
  static String companyRestore(String id) => '/api/v1/companies/$id/restore';
  static String companyStatus(String id) => '/api/v1/companies/$id/status';
  static String companyStep2(String id) => '/api/v1/companies/$id/step2';
  static String companyStep3(String id) => '/api/v1/companies/$id/step3';
  static String expenseCategoryById(String id) =>
      '/api/v1/expense-categories/$id';
  static String companyCategoryById(String id) =>
      '/api/v1/company-categories/$id';
  static String productCategoryById(String id) =>
      '/api/v1/product-categories/$id';
  static String employeeById(String id) => '/api/v1/employees/$id';
  static String employeeStep2(String id) => '/api/v1/employees/$id/step2';
  static String employeeStep3(String id) => '/api/v1/employees/$id/step3';
  static String unitById(String id) => '/api/v1/units/$id';
  static String expenseById(String id) => '/api/v1/expenses/$id';
  static String customerById(String id) => '/api/v1/customers/$id';
  static String saleById(String id) => '/api/v1/sales/$id';
  static String saleStep2(String id) => '/api/v1/sales/$id/step2';
  static String saleItems(String id) => '/api/v1/sales/$id/items';
  static String productById(String id) => '/api/v1/products/$id';
  static String productStep2(String id) => '/api/v1/products/$id/step2';
  static String productStep3(String id) => '/api/v1/products/$id/step3';
  static String productStep4(String id) => '/api/v1/products/$id/step4';
}
