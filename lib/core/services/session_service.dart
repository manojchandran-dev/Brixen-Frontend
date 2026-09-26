import '../../features/auth/domain/entities/user_role.dart';
import 'token_service.dart';

/// Thin convenience wrapper over [TokenService] for the things a screen
/// needs to know about who's logged in — role-based branching, and the
/// one company a companyAdmin/employee session belongs to.
class Session {
  Session._();

  // Prefers the server's coarse `user_type` ("superadmin"/"company"/
  // "employee") over the finer-grained `role` (e.g. "company_admin"),
  // falling back to `role` only if `user_type` wasn't returned.
  static UserRole get role =>
      UserRoleX.fromString(TokenService.userType ?? TokenService.role);
  static bool get isSuperAdmin => role == UserRole.superAdmin;

  static String? get email => TokenService.email;
  static String? get userId => TokenService.userId;
  // What `GET /api/v1/modules?employee_id=...` expects for an `employee`
  // session — falls back to the generic login id if the response didn't
  // carry a distinct employee id.
  static String? get employeeId =>
      TokenService.employeeId ?? TokenService.userId;

  /// The company id to send on a create/update call. For a superAdmin this
  /// is null — the caller must supply one via a company picker instead.
  static String? get companyId => TokenService.companyId;
  static String? get companyName => TokenService.companyName;
  static String? get companyCode => TokenService.companyCode;
  static String? get ownerName => TokenService.ownerName;
  static String? get subscriptionPlan => TokenService.subscriptionPlan;
  static String? get onboardingStatus => TokenService.onboardingStatus;
  static String? get companyStatus => TokenService.companyStatus;
}
