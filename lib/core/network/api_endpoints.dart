import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = AppConfig.baseUrl;

  static const String health         = '/api/health';
  static const String login          = '/api/v1/auth/login';
  static const String authPin        = '/api/v1/auth/pin';
  static const String authPinVerify  = '/api/v1/auth/pin/verify';
  static const String forgotPassword = '/api/v1/auth/forgot-password';
  static const String verifyOtp      = '/api/v1/auth/verify-otp';
  static const String resetPassword  = '/api/v1/auth/reset-password';
  static const String companies      = '/api/v1/companies';
  static const String expenseCategories = '/api/v1/expense-categories';
  static const String companyCategories = '/api/v1/company-categories';
  static const String employees      = '/api/v1/employees';
  static const String units          = '/api/v1/units';
  static const String expenses       = '/api/v1/expenses';
  static const String customers      = '/api/v1/customers';
  static const String sales          = '/api/v1/sales';

  static String companyById(String id)     => '/api/v1/companies/$id';
  static String companyStatus(String id)   => '/api/v1/companies/$id/status';
  static String companyStep2(String id)    => '/api/v1/companies/$id/step2';
  static String companyStep3(String id)    => '/api/v1/companies/$id/step3';
  static String expenseCategoryById(String id) => '/api/v1/expense-categories/$id';
  static String companyCategoryById(String id) => '/api/v1/company-categories/$id';
  static String employeeById(String id)    => '/api/v1/employees/$id';
  static String employeeStep2(String id)   => '/api/v1/employees/$id/step2';
  static String employeeStep3(String id)   => '/api/v1/employees/$id/step3';
  static String unitById(String id)        => '/api/v1/units/$id';
  static String expenseById(String id)     => '/api/v1/expenses/$id';
  static String customerById(String id)    => '/api/v1/customers/$id';
  static String saleById(String id)        => '/api/v1/sales/$id';
}
