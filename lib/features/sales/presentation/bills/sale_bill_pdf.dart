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
/// secondary bill (no tax) otherwise.
Future<Uint8List> buildSaleBillPdf(SaleBillData data) async {
  final fonts = await _BillFonts.load();
  final logo = await _loadLogo(data.company?.logoUrl);
  final doc = pw.Document(
    title: _billTitle(data.sale),
    author: data.company?.name,
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );
  final money = _Money(fonts.hasRupee);
  doc.addPage(
    data.sale.isGst
        ? _gstInvoice(data, money, logo)
        : _secondaryBill(data, money, logo),
  );
  return doc.save();
}

/// File name for saving or sharing, e.g. "GST-2026-27-0001.pdf".
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

// ── Shared pieces ──────────────────────────────────────────────────────────

final _date = DateFormat('dd MMM yyyy');

String _pct(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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
  final cityLine = [
    c.city,
    c.state,
    c.pincode,
  ].where((s) => s != null && s.trim().isNotEmpty && !_isPlaceholder(s));
  return [
    if (_has(c.address)) c.address!.trim(),
    if (cityLine.isNotEmpty) cityLine.join(', '),
  ];
}

bool _has(String? s) => s != null && s.trim().isNotEmpty && !_isPlaceholder(s);

/// Seed data fills unknown company fields with "Update Later" / "TBD".
bool _isPlaceholder(String s) {
  final v = s.trim().toLowerCase();
  return v == 'update later' || v == 'tbd' || v == '000000';
}

String _customerName(SaleBillData d) =>
    d.customer?.name ?? d.sale.customerName ?? 'Walk-in customer';

pw.Widget _label(String text, PdfColor color) => pw.Text(
  text.toUpperCase(),
  style: pw.TextStyle(
    fontSize: 7.5,
    color: color,
    fontWeight: pw.FontWeight.bold,
    letterSpacing: 0.8,
  ),
);

pw.Widget _logoBox(pw.ImageProvider? logo, String name, PdfColor color) {
  if (logo != null) {
    return pw.Container(
      width: 54,
      height: 54,
      child: pw.Image(logo, fit: pw.BoxFit.contain),
    );
  }
  return pw.Container(
    width: 54,
    height: 54,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _cell(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
  PdfColor? color,
  double size = 8.5,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
  child: pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

pw.Widget _totalRow(
  String label,
  String value, {
  bool strong = false,
  PdfColor? fill,
  PdfColor? textColor,
}) => pw.Container(
  color: fill,
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: strong ? 10 : 8.5,
            color: textColor,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: strong ? 10.5 : 8.5,
          color: textColor,
          fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ],
  ),
);

pw.Widget _footer(pw.Context ctx, String text, PdfColor muted) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 10),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, color: muted)),
      ),
      pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style: pw.TextStyle(fontSize: 7.5, color: muted),
      ),
    ],
  ),
);

// ── GST tax invoice ────────────────────────────────────────────────────────

const _navy = PdfColor.fromInt(0xFF1F2A44);
const _navySoft = PdfColor.fromInt(0xFFE9EDF5);
const _rule = PdfColor.fromInt(0xFFC9D0DD);
const _muted = PdfColor.fromInt(0xFF5B6475);

pw.Page _gstInvoice(SaleBillData d, _Money money, pw.ImageProvider? logo) {
  final sale = d.sale;
  final company = d.company;
  final companyGstin = _has(company?.gstNumber)
      ? company!.gstNumber!.trim().toUpperCase()
      : null;
  final customerGstin = _has(d.customer?.gstNumber)
      ? d.customer!.gstNumber!.trim().toUpperCase()
      : null;

  final rate =
      sale.taxPercentage ??
      (sale.subtotal > 0 ? sale.taxAmount / sale.subtotal * 100 : 0);
  // Different states (by GSTIN state code) → IGST; otherwise CGST + SGST.
  final supplierState = _stateCode(companyGstin);
  final placeState = _stateCode(customerGstin) ?? supplierState;
  final interState =
      supplierState != null &&
      placeState != null &&
      supplierState != placeState;
  final placeOfSupply = placeState != null
      ? '${_stateNames[placeState] ?? 'State'} ($placeState)'
      : (_has(company?.state) ? company!.state!.trim() : '—');

  final cgst = (sale.taxAmount / 2 * 100).roundToDouble() / 100;
  final sgst = sale.taxAmount - cgst;
  final lines = _lines(d);
  final half = rate / 2;

  final headers = [
    '#',
    'Item',
    'Qty',
    'Rate',
    'Taxable value',
    if (interState) 'IGST' else ...['CGST', 'SGST'],
    'Amount',
  ];
  final widths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(20),
    1: const pw.FlexColumnWidth(3.2),
    2: const pw.FixedColumnWidth(32),
    3: const pw.FlexColumnWidth(1.3),
    4: const pw.FlexColumnWidth(1.5),
    if (interState)
      5: const pw.FlexColumnWidth(1.5)
    else ...{
      5: const pw.FlexColumnWidth(1.35),
      6: const pw.FlexColumnWidth(1.35),
    },
    headers.length - 1: const pw.FlexColumnWidth(1.6),
  };

  String taxCell(double base, double pct) =>
      '${_pct(pct)}%\n${money.plain(base * pct / 100)}';

  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 26),
    footer: (ctx) => _footer(
      ctx,
      'This is a computer-generated invoice and does not need a signature.',
      _muted,
    ),
    build: (ctx) => [
      // Seller and document title.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _logoBox(logo, company?.name ?? '', _navy),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company?.name ?? '',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                  ),
                ),
                for (final l in _companyAddress(company))
                  pw.Text(l, style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 3),
                pw.Text(
                  [
                    if (companyGstin != null) 'GSTIN: $companyGstin',
                    if (_has(company?.panNumber))
                      'PAN: ${company!.panNumber!.trim().toUpperCase()}',
                  ].join('   '),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  [
                    if (_has(company?.phone)) 'Ph: ${company!.phone}',
                    if (_has(company?.email)) company!.email!,
                  ].join('   '),
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _navy, width: 0.8),
                ),
                child: pw.Text(
                  'ORIGINAL FOR RECIPIENT',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(height: 2, color: _navy),
      pw.SizedBox(height: 10),

      // Invoice details | Bill to.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _rule, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _label('Bill to', _muted),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _customerName(d),
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (_has(d.customer?.shopName))
                    pw.Text(
                      d.customer!.shopName!,
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (_has(d.customer?.address))
                    pw.Text(
                      d.customer!.address!,
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  if (_has(d.customer?.phone))
                    pw.Text(
                      'Ph: ${d.customer!.phone}',
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'GSTIN: ${customerGstin ?? 'Unregistered'}',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Table(
              border: pw.TableBorder.all(color: _rule, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.1),
                1: pw.FlexColumnWidth(1.5),
              },
              children: [
                for (final (k, v) in [
                  ('Invoice No.', sale.billNo ?? '—'),
                  ('Invoice Date', _date.format(sale.billDate)),
                  ('Place of Supply', placeOfSupply),
                  ('Reverse Charge', 'No'),
                  (
                    'Payment',
                    [
                      sale.paymentStatus,
                      if (_has(sale.paymentType)) sale.paymentType!,
                    ].join(' · '),
                  ),
                ])
                  pw.TableRow(
                    children: [
                      pw.Container(
                        color: _navySoft,
                        child: _cell(k, bold: true, size: 8),
                      ),
                      _cell(v, size: 8.5),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),

      // Items.
      pw.Table(
        border: const pw.TableBorder(
          left: pw.BorderSide(color: _rule, width: 0.8),
          right: pw.BorderSide(color: _rule, width: 0.8),
          bottom: pw.BorderSide(color: _rule, width: 0.8),
          horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
          verticalInside: pw.BorderSide(color: _rule, width: 0.5),
        ),
        columnWidths: widths,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _navy),
            repeat: true,
            children: [
              for (final (i, h) in headers.indexed)
                _cell(
                  h,
                  bold: true,
                  color: PdfColors.white,
                  size: 8,
                  align: i <= 1 ? pw.TextAlign.left : pw.TextAlign.right,
                ),
            ],
          ),
          for (final (i, it) in lines.indexed)
            pw.TableRow(
              children: [
                _cell('${i + 1}'),
                _cell(it.productName),
                _cell('${it.quantity}', align: pw.TextAlign.right),
                _cell(money.plain(it.price), align: pw.TextAlign.right),
                _cell(money.plain(it.amount), align: pw.TextAlign.right),
                if (interState)
                  _cell(taxCell(it.amount, rate), align: pw.TextAlign.right)
                else ...[
                  _cell(taxCell(it.amount, half), align: pw.TextAlign.right),
                  _cell(taxCell(it.amount, half), align: pw.TextAlign.right),
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
      pw.SizedBox(height: 10),

      // Amount in words | totals.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _label('Amount in words', _muted),
                pw.SizedBox(height: 3),
                pw.Text(
                  amountInWords(sale.totalAmount),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_has(sale.notes)) ...[
                  pw.SizedBox(height: 10),
                  _label('Notes', _muted),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    sale.notes!,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            width: 220,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _rule, width: 0.8),
            ),
            child: pw.Column(
              children: [
                _totalRow('Taxable amount', money(sale.subtotal)),
                if (interState)
                  _totalRow('IGST @ ${_pct(rate)}%', money(sale.taxAmount))
                else ...[
                  _totalRow('CGST @ ${_pct(half)}%', money(cgst)),
                  _totalRow('SGST @ ${_pct(half)}%', money(sgst)),
                ],
                _totalRow(
                  'Total',
                  money(sale.totalAmount),
                  strong: true,
                  fill: _navy,
                  textColor: PdfColors.white,
                ),
                _totalRow(
                  'Amount paid',
                  money(sale.totalAmount - sale.balance),
                ),
                _totalRow(
                  'Balance due',
                  money(sale.balance),
                  strong: sale.balance > 0,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 22),

      // Declaration | signature.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _label('Declaration', _muted),
                pw.SizedBox(height: 3),
                pw.Text(
                  'We declare that this invoice shows the actual price of the '
                  'goods described and that all particulars are true and '
                  'correct.',
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 30),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'For ${company?.name ?? ''}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 34),
              pw.Container(width: 150, height: 0.8, color: _navy),
              pw.SizedBox(height: 3),
              pw.Text(
                'Authorised Signatory',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Secondary bill (no GST) ────────────────────────────────────────────────

const _teal = PdfColor.fromInt(0xFF0F766E);
const _tealSoft = PdfColor.fromInt(0xFFE6F4F2);
const _stripe = PdfColor.fromInt(0xFFF6F8F8);

pw.Page _secondaryBill(SaleBillData d, _Money money, pw.ImageProvider? logo) {
  final sale = d.sale;
  final company = d.company;
  final lines = _lines(d);

  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 0, 36, 26),
    footer: (ctx) => _footer(
      ctx,
      'This is not a tax invoice. No GST is charged on this bill.',
      _muted,
    ),
    build: (ctx) => [
      // Coloured header band.
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: const pw.BoxDecoration(
          color: _teal,
          borderRadius: pw.BorderRadius.only(
            bottomLeft: pw.Radius.circular(10),
            bottomRight: pw.Radius.circular(10),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 46,
                height: 46,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company?.name ?? '',
                    style: pw.TextStyle(
                      fontSize: 17,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  for (final l in _companyAddress(company))
                    pw.Text(
                      l,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.white,
                      ),
                    ),
                  if (_has(company?.phone))
                    pw.Text(
                      'Ph: ${company!.phone}',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.white,
                      ),
                    ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'BILL',
                  style: pw.TextStyle(
                    fontSize: 24,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.Text(
                  sale.billNo ?? '',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),

      // Customer | date & payment.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _label('Billed to', _teal),
                pw.SizedBox(height: 3),
                pw.Text(
                  _customerName(d),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_has(d.customer?.shopName))
                  pw.Text(
                    d.customer!.shopName!,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                if (_has(d.customer?.address))
                  pw.Text(
                    d.customer!.address!,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                if (_has(d.customer?.phone))
                  pw.Text(
                    'Ph: ${d.customer!.phone}',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _tealSoft,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final (k, v) in [
                  ('Date', _date.format(sale.billDate)),
                  ('Status', sale.paymentStatus),
                  if (_has(sale.paymentType)) ('Paid by', sale.paymentType!),
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.SizedBox(
                          width: 52,
                          child: pw.Text(
                            k,
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: _muted,
                            ),
                          ),
                        ),
                        pw.Text(
                          v,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),

      // Items, striped, no tax columns.
      pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(4),
          2: pw.FixedColumnWidth(40),
          3: pw.FlexColumnWidth(1.4),
          4: pw.FlexColumnWidth(1.6),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _teal, width: 1.4),
              ),
            ),
            children: [
              for (final (i, h) in [
                '#',
                'Item',
                'Qty',
                'Rate',
                'Amount',
              ].indexed)
                _cell(
                  h,
                  bold: true,
                  color: _teal,
                  align: i <= 1 ? pw.TextAlign.left : pw.TextAlign.right,
                ),
            ],
          ),
          for (final (i, it) in lines.indexed)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isOdd ? _stripe : PdfColors.white,
              ),
              children: [
                _cell('${i + 1}', size: 9),
                _cell(it.productName, size: 9),
                _cell('${it.quantity}', align: pw.TextAlign.right, size: 9),
                _cell(
                  money.plain(it.price),
                  align: pw.TextAlign.right,
                  size: 9,
                ),
                _cell(
                  money.plain(it.amount),
                  align: pw.TextAlign.right,
                  size: 9,
                  bold: true,
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 12),

      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _has(sale.notes)
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('Notes', _teal),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        sale.notes!,
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  )
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 210,
            child: pw.Column(
              children: [
                _totalRow(
                  'Total',
                  money(sale.totalAmount),
                  strong: true,
                  fill: _teal,
                  textColor: PdfColors.white,
                ),
                _totalRow('Paid', money(sale.totalAmount - sale.balance)),
                _totalRow(
                  'Balance',
                  money(sale.balance),
                  strong: sale.balance > 0,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 28),
      pw.Center(
        child: pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 11,
            color: _teal,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
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
