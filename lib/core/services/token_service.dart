import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class TokenService {
  TokenService._();

  static const _kToken            = StorageKeys.authToken;
  static const _kRefreshToken     = StorageKeys.authRefreshToken;
  static const _kRole             = StorageKeys.authRole;
  static const _kUserType         = StorageKeys.authUserType;
  static const _kUserId           = StorageKeys.authUserId;
  static const _kEmployeeId       = StorageKeys.authEmployeeId;
  static const _kEmail            = StorageKeys.authEmail;
  static const _kCompanyId        = StorageKeys.authCompanyId;
  static const _kCompanyName      = StorageKeys.authCompanyName;
  static const _kCompanyCode      = StorageKeys.authCompanyCode;
  static const _kOwnerName        = StorageKeys.authOwnerName;
  static const _kSubscriptionPlan = StorageKeys.authSubscriptionPlan;
  static const _kOnboardingStatus = StorageKeys.authOnboardingStatus;
  static const _kCompanyStatus    = StorageKeys.authCompanyStatus;

  static String? _token;
  static String? _refreshToken;
  static String? _role;
  static String? _userType;
  static String? _userId;
  static String? _employeeId;
  static String? _email;
  static String? _companyId;
  static String? _companyName;
  static String? _companyCode;
  static String? _ownerName;
  static String? _subscriptionPlan;
  static String? _onboardingStatus;
  static String? _companyStatus;

  static String? get token        => _token;
  static String? get refreshToken => _refreshToken;
  static String? get role         => _role;
  // The server's coarse three-way split ("superadmin"/"company"/"employee")
  // — preferred over `role` for any role-based branching, since `role` can
  // carry finer-grained values (e.g. "company_admin") the app doesn't need.
  static String? get userType     => _userType;
  // The logged-in account's own id — for an `employee` login this doubles
  // as the `employee_id` the modules API expects.
  static String? get userId       => _userId;
  static String? get employeeId   => _employeeId;
  static String? get email        => _email;
  // Only set for a `companyAdmin`/`employee` login — the single company
  // that account belongs to, so those roles never need to pick one.
  // Always null for `superAdmin`, who manages many companies instead.
  static String? get companyId        => _companyId;
  static String? get companyName      => _companyName;
  static String? get companyCode      => _companyCode;
  static String? get ownerName        => _ownerName;
  static String? get subscriptionPlan => _subscriptionPlan;
  static String? get onboardingStatus => _onboardingStatus;
  static String? get companyStatus    => _companyStatus;
  static bool   get isLoggedIn    => _token != null && _token!.isNotEmpty;

  /// Call once in main() before runApp — loads tokens from disk into memory.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token             = prefs.getString(_kToken);
    _refreshToken      = prefs.getString(_kRefreshToken);
    _role              = prefs.getString(_kRole);
    _userType          = prefs.getString(_kUserType);
    _userId            = prefs.getString(_kUserId);
    _employeeId        = prefs.getString(_kEmployeeId);
    _email             = prefs.getString(_kEmail);
    _companyId         = prefs.getString(_kCompanyId);
    _companyName       = prefs.getString(_kCompanyName);
    _companyCode       = prefs.getString(_kCompanyCode);
    _ownerName         = prefs.getString(_kOwnerName);
    _subscriptionPlan  = prefs.getString(_kSubscriptionPlan);
    _onboardingStatus  = prefs.getString(_kOnboardingStatus);
    _companyStatus     = prefs.getString(_kCompanyStatus);
  }

  /// Persist tokens + role (+ everything the login response carries about
  /// the company, for company-scoped logins) after a successful login.
  ///
  /// MERGES rather than overwrites: any field left null here keeps its
  /// previously-stored value instead of being wiped. This matters because
  /// `save()` is also called for partial token refreshes (e.g. PIN unlock,
  /// which only has a fresh token/role, not the full company profile) —
  /// without merge semantics, every PIN unlock would blow away
  /// `companyId`/`ownerName`/etc. and silently break every company-scoped
  /// API call made afterward. Call [clear] first if you actually need to
  /// wipe a field (e.g. switching accounts).
  static Future<void> save({
    required String token,
    required String role,
    String? refreshToken,
    String? userType,
    String? userId,
    String? employeeId,
    String? email,
    String? companyId,
    String? companyName,
    String? companyCode,
    String? ownerName,
    String? subscriptionPlan,
    String? onboardingStatus,
    String? companyStatus,
  }) async {
    _token             = token;
    _role              = role;
    _refreshToken      = refreshToken ?? _refreshToken;
    _userType          = userType ?? _userType;
    _userId            = userId ?? _userId;
    _employeeId        = employeeId ?? _employeeId;
    _email             = email ?? _email;
    _companyId         = companyId ?? _companyId;
    _companyName       = companyName ?? _companyName;
    _companyCode       = companyCode ?? _companyCode;
    _ownerName         = ownerName ?? _ownerName;
    _subscriptionPlan  = subscriptionPlan ?? _subscriptionPlan;
    _onboardingStatus  = onboardingStatus ?? _onboardingStatus;
    _companyStatus     = companyStatus ?? _companyStatus;
    final prefs = await SharedPreferences.getInstance();
    Future<void> setIfPresent(String key, String? value) =>
        value != null ? prefs.setString(key, value) : Future.value();
    await Future.wait([
      prefs.setString(_kToken, token),
      prefs.setString(_kRole, role),
      setIfPresent(_kRefreshToken, refreshToken),
      setIfPresent(_kUserType, userType),
      setIfPresent(_kUserId, userId),
      setIfPresent(_kEmployeeId, employeeId),
      setIfPresent(_kEmail, email),
      setIfPresent(_kCompanyId, companyId),
      setIfPresent(_kCompanyName, companyName),
      setIfPresent(_kCompanyCode, companyCode),
      setIfPresent(_kOwnerName, ownerName),
      setIfPresent(_kSubscriptionPlan, subscriptionPlan),
      setIfPresent(_kOnboardingStatus, onboardingStatus),
      setIfPresent(_kCompanyStatus, companyStatus),
    ]);
  }

  /// Remove all tokens on logout.
  static Future<void> clear() async {
    _token             = null;
    _refreshToken      = null;
    _role              = null;
    _userType          = null;
    _userId            = null;
    _employeeId        = null;
    _email             = null;
    _companyId         = null;
    _companyName       = null;
    _companyCode       = null;
    _ownerName         = null;
    _subscriptionPlan  = null;
    _onboardingStatus  = null;
    _companyStatus     = null;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kToken),
      prefs.remove(_kRefreshToken),
      prefs.remove(_kRole),
      prefs.remove(_kUserType),
      prefs.remove(_kUserId),
      prefs.remove(_kEmployeeId),
      prefs.remove(_kEmail),
      prefs.remove(_kCompanyId),
      prefs.remove(_kCompanyName),
      prefs.remove(_kCompanyCode),
      prefs.remove(_kOwnerName),
      prefs.remove(_kSubscriptionPlan),
      prefs.remove(_kOnboardingStatus),
      prefs.remove(_kCompanyStatus),
    ]);
  }
}
