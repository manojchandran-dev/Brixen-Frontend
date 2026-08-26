import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/purchase.dart';
import '../providers/purchases_provider.dart';

class PurchaseDetailPage extends ConsumerWidget {
  final Purchase purchase;
  const PurchaseDetailPage({super.key, required this.purchase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final statusColor = _statusColor(purchase.paymentStatus);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: isDark ? AppColors.silverGradient : null, color: isDark ? null : AppColors.lightPrimary, borderRadius: BorderRadius.circular(10), boxShadow: AppColors.shadows([BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))])),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(purchase.supplierName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(DateFormat('dd MMM yyyy').format(purchase.billDate), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createPurchase, extra: {'purchase': purchase, 'fromMasters': false}),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 8, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentIndigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3))), child: Icon(Icons.edit_outlined, size: 18, color: AppColors.accentIndigo)),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 16, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3))), child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          Row(children: [
            _Badge(label: purchase.paymentStatus, color: statusColor),
            if (purchase.invoiceType != null) ...[const SizedBox(width: 8), _Tag(label: purchase.invoiceType!)],
          ]),
          const SizedBox(height: 20),

          if (purchase.billImagePath != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(purchase.billImagePath!), width: double.infinity, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 20),
          ],

          _Card(isDark: isDark, child: Column(children: [
            _Row(label: 'Subtotal', value: '₹${fmt.format(purchase.subtotal)}', color: cs.onSurface),
            _Divider(),
            _Row(label: 'Tax Amount', value: '₹${fmt.format(purchase.taxAmount)}', color: AppColors.accentGold),
            _Divider(),
            _Row(label: 'Total Amount', value: '₹${fmt.format(purchase.totalAmount)}', color: AppColors.accentTeal, bold: true, large: true),
          ])),
          const SizedBox(height: 14),

          _Card(isDark: isDark, child: Column(children: [
            _Row(label: 'Payment Type', value: purchase.paymentType ?? '—', color: cs.onSurface),
            _Divider(),
            _Row(label: 'Payment Status', value: purchase.paymentStatus, color: statusColor, bold: true),
          ])),
          const SizedBox(height: 14),

          if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
            _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(purchase.notes!, style: TextStyle(fontSize: 14, color: cs.onSurface)),
            ])),
            const SizedBox(height: 14),
          ],

          _Card(isDark: isDark, child: _Row(label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(purchase.createdAt), color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Delete purchase from "${purchase.supplierName}"? This cannot be undone.', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () { ref.read(purchasesProvider.notifier).deletePurchase(purchase.id); Navigator.pop(context); context.go(AppRouter.purchases); },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return AppColors.accentEmerald;
      case 'pending': return AppColors.accentGold;
      case 'partial': return AppColors.accentIndigo;
      case 'cancelled': return AppColors.accentRose;
      default: return AppColors.accentSlate;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child; final bool isDark;
  const _Card({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: AppColors.shadows([BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))])),
    child: child,
  );
}

class _Row extends StatelessWidget {
  final String label, value; final Color color; final bool bold, large;
  const _Row({required this.label, required this.value, required this.color, this.bold = false, this.large = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    Text(value, style: TextStyle(fontSize: large ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Theme.of(context).dividerColor));
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.35))),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    );
  }
}
