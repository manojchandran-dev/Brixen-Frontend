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

/// A sale's bill: the PDF's pages as images — tap anywhere to zoom into that
/// spot, pinch for more — with Download, Share and Print below.
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

  /// How many pages are zoomed in: while any is, the page list stops
  /// scrolling so a drag moves around the zoomed page instead.
  int _zoomedPages = 0;

  /// Which action is running ('download' | 'share' | 'print').
  String? _busy;

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
      await for (final page in Printing.raster(pdf, dpi: 220))
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _zoomedPages > 0
                            ? 'Drag to move around · tap to zoom out'
                            : 'Tap anywhere to zoom in · pinch for more',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: _zoomedPages > 0
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  itemCount: bill.pages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _ZoomablePage(
                    image: bill.pages[i],
                    onZoomChanged: (zoomed) =>
                        setState(() => _zoomedPages += zoomed ? 1 : -1),
                  ),
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

/// One bill page that fits the width. Tap a spot to zoom 2.5× into it (tap
/// again to zoom out), pinch for up to 5×; while zoomed, drag to move.
class _ZoomablePage extends StatefulWidget {
  final Uint8List image;
  final ValueChanged<bool> onZoomChanged;
  const _ZoomablePage({required this.image, required this.onZoomChanged});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage>
    with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _tween;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_tween != null) _zoom.value = _tween!.value;
    });
    _zoom.addListener(() {
      final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) {
        setState(() => _zoomed = zoomed);
        widget.onZoomChanged(zoomed);
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(
      begin: _zoom.value,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  /// Tap: zoom into the tapped spot, or back out.
  void _onTap(TapUpDetails d) {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    const scale = 2.5;
    final at = d.localPosition;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTapUp: _onTap,
          child: InteractiveViewer(
            transformationController: _zoom,
            minScale: 1,
            maxScale: 5,
            // Only pans while zoomed; otherwise the drag scrolls the list.
            panEnabled: _zoomed,
            child: Image.memory(
              widget.image,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Download PDF (main), Share and Print — one row, all the same height.
class _ActionBar extends StatelessWidget {
  final String? busy;
  final VoidCallback onDownload, onShare, onPrint;
  const _ActionBar({
    required this.busy,
    required this.onDownload,
    required this.onShare,
    required this.onPrint,
  });

  static const _height = 52.0;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final onBrand = isDark ? AppColors.black : AppColors.white;
    final tint = isDark ? AppColors.brandLight : AppColors.brand;

    Widget content(String id, IconData icon, String label, Color color) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        busy == id
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    Widget secondary(String id, IconData icon, String label, VoidCallback f) =>
        Expanded(
          child: SizedBox(
            height: _height,
            child: Material(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: busy == null ? f : null,
                child: content(id, icon, label, tint),
              ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ]),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: _height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.silverGradient
                      : const LinearGradient(
                          colors: [AppColors.brand, AppColors.brandDeep],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: busy == null ? onDownload : null,
                    child: content(
                      'download',
                      Icons.download_rounded,
                      'Download PDF',
                      onBrand,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          secondary('share', Icons.share_rounded, 'Share', onShare),
          const SizedBox(width: 10),
          secondary('print', Icons.print_rounded, 'Print', onPrint),
        ],
      ),
    );
  }
}
