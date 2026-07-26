enum UserRole { superAdmin, companyAdmin, employee }

extension UserRoleX on UserRole {
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'company_admin':
      case 'companyadmin':
      case 'admin':
        return UserRole.companyAdmin;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}
