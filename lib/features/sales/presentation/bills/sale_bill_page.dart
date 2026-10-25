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

/// Full-screen preview of a sale's bill PDF, with print, share and save.
/// Loads the lines, the company and the customer first.
class SaleBillPage extends ConsumerStatefulWidget {
  final Sale sale;
  const SaleBillPage({super.key, required this.sale});

  static Future<void> open(BuildContext context, Sale sale) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => SaleBillPage(sale: sale)));

  @override
  ConsumerState<SaleBillPage> createState() => _SaleBillPageState();
}

class _SaleBillPageState extends ConsumerState<SaleBillPage> {
  late Future<SaleBillData> _data = _load();

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

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${sale.isGst ? 'GST Invoice' : 'Secondary Bill'}'
          '${sale.billNo != null ? ' · ${sale.billNo}' : ''}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<SaleBillData>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorCard(
              error: snap.error!,
              onRetry: () => setState(() => _data = _load()),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return PdfPreview(
            build: (_) => buildSaleBillPdf(snap.data!),
            pdfFileName: saleBillFileName(sale),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            loadingWidget: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            previewPageMargin: const EdgeInsets.all(12),
            scrollViewDecoration: BoxDecoration(color: AppColors.background),
          );
        },
      ),
    );
  }
}
