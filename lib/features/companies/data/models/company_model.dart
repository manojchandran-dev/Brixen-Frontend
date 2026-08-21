import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    super.code,
    required super.ownerName,
    super.email,
    super.phone,
    super.secondaryEmail,
    super.website,
    super.gstNumber,
    super.panNumber,
    super.address,
    super.city,
    super.state,
    super.country,
    super.pincode,
    super.industryType,
    super.entityType,
    super.subscriptionPlan,
    super.onboardingStatus,
    super.isActive = true,
    required super.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'].toString(),
      name: json['company_name'] ?? json['name'] ?? '',
      code: json['company_code'] ?? json['code'],
      ownerName: json['owner_name'] ?? json['ownerName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      secondaryEmail: json['secondary_email'] ?? json['secondaryEmail'],
      website: json['website'],
      gstNumber: json['gst_number'] ?? json['gstNumber'],
      panNumber: json['pan_card'] ?? json['pan_number'] ?? json['panNumber'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      industryType: json['industry_type'] ?? json['industryType'],
      entityType: json['entity_type'] ?? json['entityType'],
      subscriptionPlan: json['subscription_plan'] ?? json['subscriptionPlan'],
      onboardingStatus: json['onboarding_status'] ?? json['onboardingStatus'],
      isActive: _parseStatus(json['status']) ??
          (json['is_active'] ?? json['isActive'] ?? true),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static bool? _parseStatus(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'active';
    return null;
  }
}
