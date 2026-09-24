/// `GET /api/v1/auth/me` response — the `company` object is only present
/// when `userType == 'company'`; superadmin responses omit it entirely.
class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String userType;
  final String? companyId;
  final bool hasPin;
  final String? companyName;
  final String? ownerName;
  final String? phone;
  final String? secondaryEmail;
  final String? website;

  const ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    required this.userType,
    this.companyId,
    this.hasPin = false,
    this.companyName,
    this.ownerName,
    this.phone,
    this.secondaryEmail,
    this.website,
  });

  bool get isCompany => userType == 'company';
  bool get isSuperAdmin => userType == 'superadmin';

  factory ProfileModel.fromJson(Map<String, dynamic> j) {
    final company = j['company'] is Map
        ? j['company'] as Map<String, dynamic>
        : null;
    return ProfileModel(
      id: (j['id'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      role: (j['role'] ?? '').toString(),
      userType: (j['user_type'] ?? j['userType'] ?? '').toString(),
      companyId: (j['company_id'] ?? j['companyId'])?.toString(),
      hasPin: j['hasPin'] == true,
      companyName: company?['company_name']?.toString(),
      ownerName: company?['owner_name']?.toString(),
      phone: company?['phone']?.toString(),
      secondaryEmail: company?['secondary_email']?.toString(),
      website: company?['website']?.toString(),
    );
  }
}
