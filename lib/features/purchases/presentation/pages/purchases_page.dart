import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/purchase.dart';
import '../providers/purchases_provider.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const PurchasesPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
        leading: GestureDetector(
          onTap: () => widget.fromMasters ? context.pop() : context.go(AppRouter.companies),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightTextPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: widget.fromMasters
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                  GestureDetector(onTap: () => context.pop(), child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                  Text('Purchases', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchases', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
                  purchasesAsync.whenOrNull(data: (l) => Text('${l.length} records', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))) ?? const SizedBox.shrink(),
                ],
              ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createPurchase, extra: widget.fromMasters ? 'masters' : null),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.silverGradient : null,
                color: isDark ? null : AppColors.lightTextPrimary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.add_rounded, size: 20, color: isDark ? AppColors.black : AppColors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by supplier or status…',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.silver : AppColors.lightTextPrimary, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: purchasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: cs.error, fontSize: 13))),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty ? list : list.where((p) => p.supplierName.toLowerCase().contains(q) || p.paymentStatus.toLowerCase().contains(q)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shopping_cart_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(list.isEmpty ? 'No purchases yet' : 'No results', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                      if (list.isEmpty) ...[const SizedBox(height: 6), Text('Tap + to record your first purchase', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))],
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PurchaseCard(purchase: filtered[i], isDark: isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Purchase Card ──────────────────────────────────────────────────────────

class _PurchaseCard extends ConsumerWidget {
  final Purchase purchase;
  final bool isDark;
  const _PurchaseCard({required this.purchase, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(purchase.paymentStatus);
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return GestureDetector(
      onTap: () => context.push(AppRouter.purchaseDetail, extra: purchase),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(
            children: [
              Container(width: 3, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(purchase.supplierName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface))),
                          _StatusChip(status: purchase.paymentStatus, color: statusColor),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            onSelected: (v) => _onAction(context, ref, v),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
                            itemBuilder: (_) => [
                              _menuItem(context, 'view', 'View', Icons.visibility_outlined, cs.onSurface),
                              _menuItem(context, 'edit', 'Edit', Icons.edit_outlined, AppColors.accentIndigo),
                              _menuItem(context, 'delete', 'Delete', Icons.delete_outline_rounded, AppColors.accentRose),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM yyyy').format(purchase.billDate), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        if (purchase.invoiceType != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.description_outlined, size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(purchase.invoiceType!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        _AmountChip(label: 'Subtotal', value: '₹${fmt.format(purchase.subtotal)}', color: AppColors.accentSlate),
                        const SizedBox(width: 8),
                        _AmountChip(label: 'Tax', value: '₹${fmt.format(purchase.taxAmount)}', color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        _AmountChip(label: 'Total', value: '₹${fmt.format(purchase.totalAmount)}', color: AppColors.accentTeal, bold: true),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(BuildContext context, String value, String label, IconData icon, Color color) {
    return PopupMenuItem(value: value, child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 10), Text(label, style: TextStyle(fontSize: 13, color: color))]));
  }

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'view': context.push(AppRouter.purchaseDetail, extra: purchase);
      case 'edit': context.push(AppRouter.createPurchase, extra: {'purchase': purchase, 'fromMasters': false});
      case 'delete': _confirmDelete(context, ref);
    }
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
            onPressed: () { ref.read(purchasesProvider.notifier).deletePurchase(purchase.id); Navigator.pop(context); },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':      return AppColors.accentEmerald;
      case 'pending':   return AppColors.accentGold;
      case 'partial':   return AppColors.accentIndigo;
      case 'cancelled': return AppColors.accentRose;
      default:          return AppColors.accentSlate;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status; final Color color;
  const _StatusChip({required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _AmountChip extends StatelessWidget {
  final String label, value; final Color color; final bool bold;
  const _AmountChip({required this.label, required this.value, required this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color)),
    ]),
  );
}
