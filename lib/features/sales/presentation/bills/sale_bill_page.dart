import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../companies/data/repositories/companies_repository_impl.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';
import 'sale_bill_pdf.dart';

/// A sale's bill: the PDF's pages as images you can pinch or double-tap to
/// zoom, with Download, Share and Print below.
class SaleBillPage extends ConsumerStatefulWidget {
  final Sale sale;
  const SaleBillPage({super.key, required this.sale});

  static Future<void> open(BuildContext context, Sale sale) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => SaleBillPage(sale: sale)));

  @override
  ConsumerState<SaleBillPage> createState() => _SaleBillPageState();
}

/// The built bill: the PDF itself and its pages as images.
class _Bill {
  final Uint8List pdf;
  final List<Uint8List> pages;
  const _Bill(this.pdf, this.pages);
}

class _SaleBillPageState extends ConsumerState<SaleBillPage> {
  late Future<_Bill> _bill = _build();
  final _zoom = TransformationController();
  TapDownDetails? _doubleTapAt;

  /// Zoomed in: a one-finger drag moves around the page. Not zoomed: it
  /// scrolls the pages (the two would otherwise fight over the drag).
  bool _zoomed = false;

  /// Which action is running ('download' | 'share' | 'print').
  String? _busy;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<SaleBillData> _load() async {
    final sale = widget.sale;
    final scope = Session.isSuperAdmin ? sale.companyId : null;
    final companyId = sale.companyId ?? Session.companyId;
    // Started together; the bill still prints without the company or
    // customer details if those can't load.
    final items = ref
        .read(salesRepositoryProvider)
        .getSaleItems(sale.id, companyId: scope);
    final company = companyId == null
        ? Future<Company?>.value()
        : ref
              .read(companiesRepositoryProvider)
              .getCompanyById(companyId)
              .then<Company?>((c) => c, onError: (_) => null);
    final customers = ref
        .read(customersProvider.future)
        .then((l) => l, onError: (_) => <Customer>[]);
    return SaleBillData(
      sale: sale,
      items: await items,
      company: await company,
      customer: (await customers)
          .where((c) => c.id == sale.customerId)
          .firstOrNull,
    );
  }

  Future<_Bill> _build() async {
    final pdf = await buildSaleBillPdf(await _load());
    // Sharp enough to zoom into the small print.
    final pages = <Uint8List>[
      await for (final page in Printing.raster(pdf, dpi: 200))
        await page.toPng(),
    ];
    return _Bill(pdf, pages);
  }

  String get _fileName => saleBillFileName(widget.sale);

  Future<void> _run(String action, Future<void> Function() task) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not $action the bill: $e'),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _download(_Bill b) => _run('download', () async {
    final name = _fileName.replaceAll(RegExp(r'\.pdf$'), '');
    final saved = await FileSaver.instance.saveAs(
      name: name,
      bytes: b.pdf,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (saved != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved $_fileName')));
    }
  });

  Future<void> _share(_Bill b) =>
      _run('share', () => Printing.sharePdf(bytes: b.pdf, filename: _fileName));

  Future<void> _print(_Bill b) => _run(
    'print',
    () => Printing.layoutPdf(onLayout: (_) async => b.pdf, name: _fileName),
  );

  /// Double tap: zoom 2.5× into the tapped spot, or back out.
  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.isGst ? 'GST Invoice' : 'Secondary Bill',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (sale.billNo != null)
              Text(
                sale.billNo!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      body: FutureBuilder<_Bill>(
        future: _bill,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorCard(
              error: snap.error!,
              onRetry: () => setState(() => _bill = _build()),
            );
          }
          final bill = snap.data;
          if (bill == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 14),
                  Text(
                    'Preparing the bill…',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onDoubleTapDown: (d) => _doubleTapAt = d,
                      onDoubleTap: _toggleZoom,
                      child: InteractiveViewer(
                        transformationController: _zoom,
                        minScale: 1,
                        maxScale: 5,
                        panEnabled: _zoomed,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: ListView(
                          physics: _zoomed
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          children: [
                            for (final page in bill.pages)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    page,
                                    fit: BoxFit.fitWidth,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // How to zoom, until the bill is zoomed.
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _zoom,
                        builder: (context, m, _) => m.getMaxScaleOnAxis() > 1.01
                            ? _ZoomChip(
                                icon: Icons.zoom_out_map_rounded,
                                label: 'Reset zoom',
                                onTap: () => _zoom.value = Matrix4.identity(),
                              )
                            : const _ZoomChip(
                                icon: Icons.pinch_rounded,
                                label: 'Pinch or double-tap to zoom',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              _ActionBar(
                busy: _busy,
                onDownload: () => _download(bill),
                onShare: () => _share(bill),
                onPrint: () => _print(bill),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ZoomChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ZoomChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Download (main action), Share and Print.
class _ActionBar extends StatelessWidget {
  final String? busy;
  final VoidCallback onDownload, onShare, onPrint;
  const _ActionBar({
    required this.busy,
    required this.onDownload,
    required this.onShare,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final fg = isDark ? AppColors.black : AppColors.white;
    Widget spinner(Color c) => SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: c),
    );

    Widget side(String id, IconData icon, String label, VoidCallback onTap) =>
        Expanded(
          child: OutlinedButton(
            onPressed: busy == null ? onTap : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                busy == id
                    ? spinner(AppColors.brand)
                    : Icon(icon, size: 20, color: AppColors.brand),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ]),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.silverGradient
                    : const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDeep],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: busy == null ? onDownload : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        busy == 'download'
                            ? spinner(fg)
                            : Icon(Icons.download_rounded, color: fg),
                        const SizedBox(width: 8),
                        Text(
                          'Download PDF',
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          side('share', Icons.share_rounded, 'Share', onShare),
          const SizedBox(width: 10),
          side('print', Icons.print_rounded, 'Print', onPrint),
        ],
      ),
    );
  }
}
