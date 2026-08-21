import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    super.shopName,
    super.phone,
    super.email,
    super.address,
    super.gstNumber,
    required super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      shopName: json['shop_name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      gstNumber: json['gst_number'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Request body for create/update — server generates `id`, so it's never sent.
  static Map<String, dynamic> toBody(Customer c) => {
        'name': c.name,
        if (c.shopName != null && c.shopName!.isNotEmpty) 'shop_name': c.shopName,
        if (c.phone != null && c.phone!.isNotEmpty) 'phone': c.phone,
        if (c.email != null && c.email!.isNotEmpty) 'email': c.email,
        if (c.gstNumber != null && c.gstNumber!.isNotEmpty) 'gst_number': c.gstNumber,
        if (c.address != null && c.address!.isNotEmpty) 'address': c.address,
      };
}
