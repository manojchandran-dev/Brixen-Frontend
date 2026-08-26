import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/sale.dart';
import '../providers/sales_provider.dart';

class SaleDetailPage extends ConsumerWidget {
  final Sale sale;
  const SaleDetailPage({super.key, required this.sale});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return AppColors.positive;
      case 'pending': return AppColors.brandLight;
      case 'partial': return AppColors.brand;
      case 'cancelled': return AppColors.ink;
      default: return AppColors.brandDeep;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Delete this sale? This cannot be undone.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(salesProvider.notifier).deleteSale(sale.id);
                if (context.mounted) context.go(AppRouter.sales);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final statusColor = _statusColor(sale.paymentStatus);
    final title = sale.customerName ?? sale.invoiceType ?? 'Sale';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.highlightShadow(0.8), blurRadius: 4, offset: const Offset(-2, -2)),
              ]),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Sales', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))),
            ]),
          ),
          Text(DateFormat('dd MMM yyyy').format(sale.billDate), style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(
              AppRouter.createSale,
              extra: {'sale': sale, 'fromMasters': false, 'fromMenu': false},
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.white),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]),
              ),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Status badge row
          Row(
            children: [
              _StatusBadge(status: sale.paymentStatus, color: statusColor),
              if (sale.invoiceType != null) ...[
                const SizedBox(width: 8),
                _TagChip(label: sale.invoiceType!),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Bill image
          if (sale.billImagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(sale.billImagePath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Amount breakdown card
          _SectionCard(
            child: Column(
              children: [
                _DetailRow(icon: Icons.receipt_long_rounded, iconColor: AppColors.brand, label: 'Subtotal', value: '₹${fmt.format(sale.subtotal)}', valueColor: AppColors.ink),
                _Divider(),
                _DetailRow(icon: Icons.percent_rounded, iconColor: AppColors.brandLight, label: 'Tax Amount', value: '₹${fmt.format(sale.taxAmount)}', valueColor: AppColors.brand),
                _Divider(),
                _DetailRow(icon: Icons.payments_rounded, iconColor: AppColors.positive, label: 'Total Amount', value: '₹${fmt.format(sale.totalAmount)}', valueColor: AppColors.positive, bold: true, large: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment info
          _SectionCard(
            child: Column(
              children: [
                if (sale.customerName != null) ...[
                  _DetailRow(icon: Icons.person_rounded, iconColor: AppColors.brand, label: 'Customer', value: sale.customerName!, valueColor: AppColors.ink),
                  _Divider(),
                ],
                _DetailRow(icon: Icons.credit_card_rounded, iconColor: AppColors.positive, label: 'Payment Type', value: sale.paymentType ?? '—', valueColor: AppColors.ink),
                _Divider(),
                _DetailRow(icon: Icons.sync_alt_rounded, iconColor: AppColors.brandDeep, label: 'Payment Status', value: sale.paymentStatus, valueColor: statusColor, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Text(sale.notes!, style: TextStyle(fontSize: 14, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meta info
          _SectionCard(
            child: _DetailRow(icon: Icons.history_rounded, iconColor: AppColors.brandLight, label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(sale.createdAt), valueColor: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
        ]),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final bool large;
  const _DetailRow({
    this.icon,
    this.iconColor = AppColors.brand,
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.accentGradient(iconColor)),
              shape: BoxShape.circle,
              boxShadow: AppColors.shadows([BoxShadow(color: iconColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]),
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(width: 12),
        ],
        Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.textHint)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: large ? 15 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))]),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}
