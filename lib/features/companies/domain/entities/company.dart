import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String ownerName;
  final String? email;
  final String? phone;
  final String? secondaryEmail;
  final String? website;
  final String? gstNumber;
  final String? panNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? industryType;
  final String? entityType;
  final String? subscriptionPlan;
  final String? onboardingStatus;
  final bool isActive;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.code,
    required this.ownerName,
    this.email,
    this.phone,
    this.secondaryEmail,
    this.website,
    this.gstNumber,
    this.panNumber,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.industryType,
    this.entityType,
    this.subscriptionPlan,
    this.onboardingStatus,
    this.isActive = true,
    required this.createdAt,
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Company copyWith({
    String? name,
    String? code,
    String? ownerName,
    String? email,
    String? phone,
    String? secondaryEmail,
    String? website,
    String? gstNumber,
    String? panNumber,
    String? address,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? industryType,
    String? entityType,
    String? subscriptionPlan,
    String? onboardingStatus,
    bool? isActive,
  }) =>
      Company(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        ownerName: ownerName ?? this.ownerName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        secondaryEmail: secondaryEmail ?? this.secondaryEmail,
        website: website ?? this.website,
        gstNumber: gstNumber ?? this.gstNumber,
        panNumber: panNumber ?? this.panNumber,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
        pincode: pincode ?? this.pincode,
        industryType: industryType ?? this.industryType,
        entityType: entityType ?? this.entityType,
        subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
        onboardingStatus: onboardingStatus ?? this.onboardingStatus,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, code, email, isActive, createdAt];
}
