import 'dart:async';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../companies/domain/entities/company.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';

/// Everything a printed bill needs. [company] and [customer] may be missing
/// (not loaded, or a walk-in sale); the bill leaves those parts out.
class SaleBillData {
  final Sale sale;
  final List<SaleItem> items;
  final Company? company;
  final Customer? customer;

  const SaleBillData({
    required this.sale,
    required this.items,
    this.company,
    this.customer,
  });
}

/// Builds the bill PDF: a GST tax invoice for [BillType.gst] sales, a plain
/// bill (no tax) for secondary sales. Both are black and white, so they
/// print cleanly on any printer.
Future<Uint8List> buildSaleBillPdf(SaleBillData data) async {
  final fonts = await _BillFonts.load();
  final logo = await _loadLogo(data.company?.logoUrl);
  final doc = pw.Document(
    title: _billTitle(data.sale),
    author: data.company?.name,
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );
  doc.addPage(_bill(data, _Money(fonts.hasRupee), logo));
  return doc.save();
}

/// File name for saving or sharing, e.g. "C7G2627-0001.pdf".
String saleBillFileName(Sale sale) {
  final no = sale.billNo ?? sale.id;
  return '${no.replaceAll('/', '-')}.pdf';
}

String _billTitle(Sale s) =>
    '${s.isGst ? 'Tax Invoice' : 'Bill'} ${s.billNo ?? ''}'.trim();

// ── Fonts, logo, money ─────────────────────────────────────────────────────

class _BillFonts {
  final pw.Font regular, bold;

  /// The built-in PDF fonts have no ₹ sign; amounts then use "Rs.".
  final bool hasRupee;
  const _BillFonts(this.regular, this.bold, this.hasRupee);

  static Future<_BillFonts> load() async {
    try {
      final r = await PdfGoogleFonts.notoSansRegular().timeout(
        const Duration(seconds: 8),
      );
      final b = await PdfGoogleFonts.notoSansBold().timeout(
        const Duration(seconds: 8),
      );
      return _BillFonts(r, b, true);
    } catch (_) {
      // Offline: fall back to the fonts built into every PDF reader.
      return _BillFonts(pw.Font.helvetica(), pw.Font.helveticaBold(), false);
    }
  }
}

Future<pw.ImageProvider?> _loadLogo(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    return await networkImage(url).timeout(const Duration(seconds: 8));
  } catch (_) {
    return null;
  }
}

class _Money {
  final bool rupee;
  const _Money(this.rupee);
  static final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  String call(double v) => '${rupee ? '₹' : 'Rs. '}${_fmt.format(v)}';
  String plain(double v) => _fmt.format(v);
}

// ── Palette: black, one grey for secondary text, one for hairlines ─────────

const _ink = PdfColors.black;
const _muted = PdfColor.fromInt(0xFF555555);
const _hair = PdfColor.fromInt(0xFFBBBBBB);

// ── Helpers ────────────────────────────────────────────────────────────────

final _date = DateFormat('dd MMM yyyy');

String _pct(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

bool _has(String? s) => s != null && s.trim().isNotEmpty && !_isPlaceholder(s);

/// Seed data fills unknown company fields with "Update Later" / "TBD".
bool _isPlaceholder(String s) {
  final v = s.trim().toLowerCase();
  return v == 'update later' || v == 'tbd' || v == '000000';
}

/// Lines to print. A sale saved without products shows one summary line.
List<SaleItem> _lines(SaleBillData d) => d.items.isNotEmpty
    ? d.items
    : [
        SaleItem(
          productId: '',
          productName: d.sale.invoiceType ?? 'Sale',
          priceType: 'retail',
          price: d.sale.subtotal,
          quantity: 1,
        ),
      ];

List<String> _companyAddress(Company? c) {
  if (c == null) return const [];
  final cityLine = [c.city, c.state, c.pincode].where(_has);
  return [
    if (_has(c.address)) c.address!.trim(),
    if (cityLine.isNotEmpty) cityLine.join(', '),
  ];
}

String _customerName(SaleBillData d) =>
    d.customer?.name ?? d.sale.customerName ?? 'Walk-in customer';

pw.TextStyle _t(double size, {bool bold = false, PdfColor color = _ink}) =>
    pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      lineSpacing: 1.5,
    );

/// Small spaced-out caption above a block: "BILL TO", "AMOUNT IN WORDS".
pw.Widget _caption(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.Text(
    text.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 7,
      color: _muted,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1.2,
    ),
  ),
);

pw.Widget _rule({double width = 0.6, PdfColor color = _ink}) =>
    pw.Container(height: width, color: color);

/// "Label   value" pair, label muted.
pw.Widget _kv(String k, String v, {double labelWidth = 78}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 1.6),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: labelWidth,
        child: pw.Text(k, style: _t(8.5, color: _muted)),
      ),
      pw.Expanded(child: pw.Text(v, style: _t(8.5, bold: true))),
    ],
  ),
);

pw.Widget _cell(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
  double size = 8.5,
  PdfColor color = _ink,
  String? sub,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
  child: pw.Column(
    crossAxisAlignment: align == pw.TextAlign.right
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        text,
        textAlign: align,
        style: _t(size, bold: bold, color: color),
      ),
      if (sub != null)
        pw.Text(
          sub,
          textAlign: align,
          style: _t(7, color: _muted),
        ),
    ],
  ),
);

pw.Widget _totalRow(String label, String value, {bool strong = false}) =>
    pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: strong ? 6 : 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: _t(
                strong ? 10.5 : 8.5,
                bold: strong,
                color: strong ? _ink : _muted,
              ),
            ),
          ),
          pw.Text(value, style: _t(strong ? 11.5 : 8.5, bold: strong)),
        ],
      ),
    );

// ── The bill ───────────────────────────────────────────────────────────────

pw.Page _bill(SaleBillData d, _Money money, pw.ImageProvider? logo) {
  final sale = d.sale;
  final gst = sale.isGst;
  final company = d.company;
  final customer = d.customer;
  final companyGstin = _has(company?.gstNumber)
      ? company!.gstNumber!.trim().toUpperCase()
      : null;
  final customerGstin = _has(customer?.gstNumber)
      ? customer!.gstNumber!.trim().toUpperCase()
      : null;

  // GST split: different states (by GSTIN state code) → IGST, else CGST+SGST.
  final rate = !gst
      ? 0.0
      : sale.taxPercentage ??
            (sale.subtotal > 0 ? sale.taxAmount / sale.subtotal * 100 : 0.0);
  final supplierState = _stateCode(companyGstin);
  final placeState = _stateCode(customerGstin) ?? supplierState;
  final interState =
      supplierState != null &&
      placeState != null &&
      supplierState != placeState;
  final placeOfSupply = placeState != null
      ? '${_stateNames[placeState]} ($placeState)'
      : (_has(company?.state) ? company!.state!.trim() : '—');
  final half = rate / 2;
  final cgst = (sale.taxAmount / 2 * 100).roundToDouble() / 100;
  final sgst = sale.taxAmount - cgst;
  final lines = _lines(d);

  // ── Items table layout ──
  final headers = [
    '#',
    'Description',
    'Qty',
    'Rate',
    if (gst) ...[
      'Taxable',
      if (interState) 'IGST' else ...['CGST', 'SGST'],
    ],
    'Amount',
  ];
  final numericFrom = 2; // columns from here on are right-aligned
  final widths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(18),
    1: const pw.FlexColumnWidth(3.4),
    2: const pw.FixedColumnWidth(34),
    for (var i = 3; i < headers.length; i++) i: const pw.FlexColumnWidth(1.4),
  };

  String taxAmt(double base, double pct) => money.plain(base * pct / 100);

  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 28),
    footer: (ctx) => pw.Column(
      children: [
        _rule(width: 0.4, color: _hair),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                gst
                    ? 'This is a computer-generated invoice.'
                    : 'This is not a tax invoice. No GST has been charged.',
                style: _t(7, color: _muted),
              ),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: _t(7, color: _muted),
            ),
          ],
        ),
      ],
    ),
    build: (ctx) => [
      // ── Header: seller | document title and number ──
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            pw.SizedBox(
              width: 48,
              height: 48,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company?.name ?? '', style: _t(15, bold: true)),
                pw.SizedBox(height: 3),
                for (final l in _companyAddress(company))
                  pw.Text(l, style: _t(8.5, color: _muted)),
                if (_has(company?.phone) || _has(company?.email))
                  pw.Text(
                    [
                      if (_has(company?.phone)) 'Ph: ${company!.phone}',
                      if (_has(company?.email)) company!.email!,
                    ].join('  ·  '),
                    style: _t(8.5, color: _muted),
                  ),
                if (gst && (companyGstin != null || _has(company?.panNumber)))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      [
                        if (companyGstin != null) 'GSTIN  $companyGstin',
                        if (_has(company?.panNumber))
                          'PAN  ${company!.panNumber!.trim().toUpperCase()}',
                      ].join('     '),
                      style: _t(8.5, bold: true),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                gst ? 'TAX INVOICE' : 'BILL',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                gst ? 'Original for recipient' : 'Without GST',
                style: _t(7.5, color: _muted),
              ),
              pw.SizedBox(height: 8),
              pw.Text(sale.billNo ?? '—', style: _t(10, bold: true)),
              pw.Text(
                _date.format(sale.billDate),
                style: _t(8.5, color: _muted),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      _rule(width: 1.2),
      pw.SizedBox(height: 14),

      // ── Bill to | details ──
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _caption('Bill to'),
                pw.Text(_customerName(d), style: _t(10.5, bold: true)),
                if (_has(customer?.shopName))
                  pw.Text(customer!.shopName!, style: _t(8.5)),
                if (_has(customer?.address))
                  pw.Text(customer!.address!, style: _t(8.5, color: _muted)),
                if (_has(customer?.phone))
                  pw.Text(
                    'Ph: ${customer!.phone}',
                    style: _t(8.5, color: _muted),
                  ),
                if (gst)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      'GSTIN  ${customerGstin ?? 'Unregistered'}',
                      style: _t(8.5, bold: true),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.SizedBox(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _caption('Details'),
                if (gst) ...[
                  _kv('Place of supply', placeOfSupply),
                  _kv('Reverse charge', 'No'),
                ],
                _kv(
                  'Payment',
                  [
                    sale.paymentStatus,
                    if (_has(sale.paymentType)) sale.paymentType!,
                  ].join(' · '),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 18),

      // ── Items: rules only, no fills ──
      pw.Table(
        columnWidths: widths,
        border: const pw.TableBorder(
          top: pw.BorderSide(color: _ink, width: 1),
          bottom: pw.BorderSide(color: _ink, width: 1),
          horizontalInside: pw.BorderSide(color: _hair, width: 0.4),
        ),
        children: [
          pw.TableRow(
            repeat: true,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.8)),
            ),
            children: [
              for (final (i, h) in headers.indexed)
                _cell(
                  h.toUpperCase(),
                  bold: true,
                  size: 7.5,
                  align: i >= numericFrom
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                ),
            ],
          ),
          for (final (i, it) in lines.indexed)
            pw.TableRow(
              children: [
                _cell('${i + 1}', color: _muted),
                _cell(
                  it.productName,
                  sub: it.priceType == 'wholesale' ? 'Wholesale' : null,
                ),
                _cell('${it.quantity}', align: pw.TextAlign.right),
                _cell(money.plain(it.price), align: pw.TextAlign.right),
                if (gst) ...[
                  _cell(money.plain(it.amount), align: pw.TextAlign.right),
                  if (interState)
                    _cell(
                      taxAmt(it.amount, rate),
                      sub: '@ ${_pct(rate)}%',
                      align: pw.TextAlign.right,
                    )
                  else
                    for (var k = 0; k < 2; k++)
                      _cell(
                        taxAmt(it.amount, half),
                        sub: '@ ${_pct(half)}%',
                        align: pw.TextAlign.right,
                      ),
                ],
                _cell(
                  money.plain(it.amount * (1 + rate / 100)),
                  align: pw.TextAlign.right,
                  bold: true,
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 14),

      // ── Amount in words / notes | totals ──
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _caption('Amount in words'),
                pw.Text(
                  amountInWords(sale.totalAmount),
                  style: _t(9, bold: true),
                ),
                if (_has(sale.notes)) ...[
                  pw.SizedBox(height: 12),
                  _caption('Notes'),
                  pw.Text(sale.notes!, style: _t(8.5)),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 28),
          pw.SizedBox(
            width: 210,
            child: pw.Column(
              children: [
                if (gst) ...[
                  _totalRow('Taxable amount', money(sale.subtotal)),
                  if (interState)
                    _totalRow('IGST @ ${_pct(rate)}%', money(sale.taxAmount))
                  else ...[
                    _totalRow('CGST @ ${_pct(half)}%', money(cgst)),
                    _totalRow('SGST @ ${_pct(half)}%', money(sgst)),
                  ],
                ] else
                  _totalRow('Subtotal', money(sale.subtotal)),
                pw.SizedBox(height: 3),
                _rule(width: 1),
                _totalRow(
                  gst ? 'Invoice total' : 'Total',
                  money(sale.totalAmount),
                  strong: true,
                ),
                _rule(width: 1),
                pw.SizedBox(height: 3),
                _totalRow(
                  'Amount paid',
                  money(sale.totalAmount - sale.balance),
                ),
                _totalRow('Balance due', money(sale.balance)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 36),

      // ── Declaration / thanks | signature ──
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: gst
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _caption('Declaration'),
                      pw.Text(
                        'We declare that this invoice shows the actual price of '
                        'the goods described and that all particulars are true '
                        'and correct.',
                        style: _t(8, color: _muted),
                      ),
                    ],
                  )
                : pw.Text(
                    'Thank you for your business.',
                    style: _t(9.5, bold: true),
                  ),
          ),
          pw.SizedBox(width: 36),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('For ${company?.name ?? ''}', style: _t(8.5, bold: true)),
              pw.SizedBox(height: 32),
              pw.SizedBox(width: 150, child: _rule(width: 0.6)),
              pw.SizedBox(height: 3),
              pw.Text('Authorised signatory', style: _t(7.5, color: _muted)),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Amount in words (Indian system) ────────────────────────────────────────

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _below100(int n) => n < 20
    ? _ones[n]
    : '${_tens[n ~/ 10]}${n % 10 > 0 ? ' ${_ones[n % 10]}' : ''}';

String _below1000(int n) {
  final h = n ~/ 100, r = n % 100;
  return [if (h > 0) '${_ones[h]} Hundred', if (r > 0) _below100(r)].join(' ');
}

String _words(int n) {
  if (n == 0) return 'Zero';
  final parts = <String>[];
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  if (crore > 0) parts.add('${_words(crore)} Crore');
  if (lakh > 0) parts.add('${_below100(lakh)} Lakh');
  if (thousand > 0) parts.add('${_below100(thousand)} Thousand');
  if (n > 0) parts.add(_below1000(n));
  return parts.join(' ');
}

/// "Rupees One Thousand Two Hundred Fifty and Fifty Paise Only".
String amountInWords(double amount) {
  final paise = (amount * 100).round();
  final rupees = paise ~/ 100, p = paise % 100;
  return 'Rupees ${_words(rupees)}'
      '${p > 0 ? ' and ${_below100(p)} Paise' : ''} Only';
}

// ── GST state codes ────────────────────────────────────────────────────────

/// The state code is the first two digits of a GSTIN.
String? _stateCode(String? gstin) {
  if (gstin == null || gstin.length < 2) return null;
  final code = gstin.substring(0, 2);
  return _stateNames.containsKey(code) ? code : null;
}

const _stateNames = {
  '01': 'Jammu & Kashmir',
  '02': 'Himachal Pradesh',
  '03': 'Punjab',
  '04': 'Chandigarh',
  '05': 'Uttarakhand',
  '06': 'Haryana',
  '07': 'Delhi',
  '08': 'Rajasthan',
  '09': 'Uttar Pradesh',
  '10': 'Bihar',
  '11': 'Sikkim',
  '12': 'Arunachal Pradesh',
  '13': 'Nagaland',
  '14': 'Manipur',
  '15': 'Mizoram',
  '16': 'Tripura',
  '17': 'Meghalaya',
  '18': 'Assam',
  '19': 'West Bengal',
  '20': 'Jharkhand',
  '21': 'Odisha',
  '22': 'Chhattisgarh',
  '23': 'Madhya Pradesh',
  '24': 'Gujarat',
  '26': 'Dadra & Nagar Haveli and Daman & Diu',
  '27': 'Maharashtra',
  '29': 'Karnataka',
  '30': 'Goa',
  '31': 'Lakshadweep',
  '32': 'Kerala',
  '33': 'Tamil Nadu',
  '34': 'Puducherry',
  '35': 'Andaman & Nicobar Islands',
  '36': 'Telangana',
  '37': 'Andhra Pradesh',
  '38': 'Ladakh',
};
