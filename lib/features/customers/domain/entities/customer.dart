class Customer {
  final String id;
  final String name;
  final String? shopName;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.shopName,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? shopName,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
