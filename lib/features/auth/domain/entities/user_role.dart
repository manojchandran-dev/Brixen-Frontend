enum UserRole { superAdmin, companyAdmin, employee }

extension UserRoleX on UserRole {
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'company_admin':
      case 'companyadmin':
      case 'company':
      case 'admin':
        return UserRole.companyAdmin;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }

  /// Canonical `user_type` value the server expects back — e.g. on
  /// `GET /api/v1/modules?user_type=...`.
  String get apiValue => switch (this) {
    UserRole.superAdmin => 'superadmin',
    UserRole.companyAdmin => 'company',
    UserRole.employee => 'employee',
  };
}
