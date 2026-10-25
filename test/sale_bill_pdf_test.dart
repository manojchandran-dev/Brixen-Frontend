import 'dart:io';

import 'package:brixen/features/companies/domain/entities/company.dart';
import 'package:brixen/features/customers/domain/entities/customer.dart';
import 'package:brixen/features/sales/domain/entities/sale.dart';
import 'package:brixen/features/sales/domain/entities/sale_item.dart';
import 'package:brixen/features/sales/presentation/bills/sale_bill_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('amountInWords uses the Indian system', () {
    expect(amountInWords(0), 'Rupees Zero Only');
    expect(
      amountInWords(1250.5),
      'Rupees One Thousand Two Hundred Fifty and Fifty Paise Only',
    );
    expect(
      amountInWords(12345678),
      'Rupees One Crore Twenty Three Lakh Forty Five Thousand Six Hundred Seventy Eight Only',
    );
  });

  final company = Company(
    id: '7',
    name: 'Brixen Garments',
    ownerName: 'Owner',
    phone: '9876543210',
    email: 'accounts@example.com',
    gstNumber: '33ABCDE1234F1Z5',
    panNumber: 'ABCDE1234F',
    address: '12 Market Road',
    city: 'Tiruppur',
    state: 'Tamil Nadu',
    pincode: '641601',
    createdAt: DateTime(2026),
  );
  final customer = Customer(
    id: 'CUS1',
    name: 'Ravi Kumar',
    shopName: 'Ravi Textiles',
    phone: '9000000000',
    address: '4 Gandhi Street, Coimbatore',
    gstNumber: '33PQRSX5678L1Z2',
    createdAt: DateTime(2026),
  );
  const items = [
    SaleItem(
      productId: 'P1',
      productName: 'Cotton T-Shirt (M)',
      priceType: 'wholesale',
      price: 250,
      quantity: 20,
    ),
    SaleItem(
      productId: 'P2',
      productName: 'Polo T-Shirt (L)',
      priceType: 'retail',
      price: 480,
      quantity: 5,
    ),
  ];

  Sale sale(String type) => Sale(
    id: 'SAL1',
    billType: type,
    billNo: type == BillType.gst ? 'C7G2627/0001' : 'C7S2627/0001',
    billDate: DateTime(2026, 10, 25),
    customerId: 'CUS1',
    subtotal: 7400,
    taxPercentage: type == BillType.gst ? 5 : 0,
    taxAmount: type == BillType.gst ? 370 : 0,
    totalAmount: type == BillType.gst ? 7770 : 7400,
    amountPaid: 5000,
    paymentType: 'UPI',
    paymentStatus: 'Partial',
    notes: 'Delivery by courier.',
    createdAt: DateTime(2026, 10, 25),
  );

  for (final type in [BillType.gst, BillType.secondary]) {
    test('builds the $type bill', () async {
      final s = sale(type);
      final bytes = await buildSaleBillPdf(
        SaleBillData(
          sale: s,
          items: items,
          company: company,
          customer: customer,
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final out = Platform.environment['BILL_PDF_OUT'];
      if (out != null) {
        File('$out/${saleBillFileName(s)}').writeAsBytesSync(bytes);
      }
    });
  }

  test('a sale without lines still prints', () async {
    final bytes = await buildSaleBillPdf(
      SaleBillData(sale: sale(BillType.secondary), items: const []),
    );
    expect(bytes, isNotEmpty);
  });
}
