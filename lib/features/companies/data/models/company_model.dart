import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    super.code,
    required super.ownerName,
    required super.email,
    super.phone,
    super.address,
    super.city,
    super.state,
    super.country,
    super.pincode,
    super.industryType,
    super.entityType,
    super.panNumber,
    super.subscriptionPlan,
    super.isActive = true,
    required super.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'],
      ownerName: json['owner_name'] ?? json['ownerName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      industryType: json['industry_type'] ?? json['industryType'],
      entityType: json['entity_type'] ?? json['entityType'],
      panNumber: json['pan_number'] ?? json['panNumber'],
      subscriptionPlan: json['subscription_plan'] ?? json['subscriptionPlan'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'owner_name': ownerName,
        'email': email,
        if (code != null) 'code': code,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (pincode != null) 'pincode': pincode,
        if (industryType != null) 'industry_type': industryType,
        if (entityType != null) 'entity_type': entityType,
        if (panNumber != null) 'pan_number': panNumber,
        if (subscriptionPlan != null) 'subscription_plan': subscriptionPlan,
        'is_active': isActive,
      };
}
