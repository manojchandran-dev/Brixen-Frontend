import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String ownerName;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? industryType;
  final String? entityType;
  final String? panNumber;
  final String? subscriptionPlan;
  final bool isActive;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.code,
    required this.ownerName,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.industryType,
    this.entityType,
    this.panNumber,
    this.subscriptionPlan,
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

  Company copyWith({bool? isActive}) => Company(
        id: id,
        name: name,
        code: code,
        ownerName: ownerName,
        email: email,
        phone: phone,
        address: address,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
        industryType: industryType,
        entityType: entityType,
        panNumber: panNumber,
        subscriptionPlan: subscriptionPlan,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, code, email, isActive, createdAt];
}
