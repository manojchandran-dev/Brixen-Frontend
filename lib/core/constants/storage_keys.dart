/// Every SharedPreferences key string used across the app, centralized so
/// no two features can accidentally collide on the same key. Values are
/// unchanged from where they used to live — existing installs keep reading
/// the same stored data.
class StorageKeys {
  StorageKeys._();

  // TokenService
  static const authToken = 'auth_token';
  static const authRefreshToken = 'auth_refresh_token';
  static const authRole = 'auth_role';
  static const authUserType = 'auth_user_type';
  static const authUserId = 'auth_user_id';
  static const authEmployeeId = 'auth_employee_id';
  static const authEmail = 'auth_email';
  static const authCompanyId = 'auth_company_id';
  static const authCompanyName = 'auth_company_name';
  static const authCompanyCode = 'auth_company_code';
  static const authOwnerName = 'auth_owner_name';
  static const authSubscriptionPlan = 'auth_subscription_plan';
  static const authOnboardingStatus = 'auth_onboarding_status';
  static const authCompanyStatus = 'auth_company_status';

  // ThemeCubit
  static const darkModeEnabled = 'dark_mode_enabled';

  // SecurityLocalSource
  static const securityPin = 'sec_pin';
  static const securityPinEnabled = 'sec_pin_enabled';
  static const securityBioEnabled = 'sec_bio_enabled';

  // AccountStore
  static const savedAccounts = 'saved_accounts';
}
