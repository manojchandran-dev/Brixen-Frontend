import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
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
      drawer: widget.fromMasters ? null : const AppDrawer(),
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
        leading: widget.fromMasters
            ? GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? cs.surfaceContainerHighest
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.shadows([
                      BoxShadow(
                        color: AppColors.shadowDark.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppColors.highlightShadow(0.8),
                        blurRadius: 4,
                        offset: const Offset(-2, -2),
                      ),
                    ]),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
              )
            : Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.highlightShadow(0.8),
                          blurRadius: 4,
                          offset: const Offset(-2, -2),
                        ),
                      ]),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
        title: widget.fromMasters
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Masters',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      'Purchases',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchases',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  purchasesAsync.whenOrNull(
                        data: (l) => Text(
                          '${l.length} records',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
        actions: [
          GestureDetector(
            onTap: () => context.push(
              AppRouter.createPurchase,
              extra: widget.fromMasters ? 'masters' : null,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.silverGradient
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brand, AppColors.brandDeep],
                      ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: isDark ? 0.0 : 0.4,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: isDark ? AppColors.black : AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.highlightShadow(0.85),
                          blurRadius: 6,
                          offset: const Offset(-3, -3),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by supplier or status…',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          Expanded(
            child: purchasesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(purchasesProvider),
              ),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list
                          .where(
                            (p) =>
                                p.supplierName.toLowerCase().contains(q) ||
                                p.paymentStatus.toLowerCase().contains(q),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No purchases yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (list.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to record your first purchase',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _PurchaseCard(purchase: filtered[i], index: i),
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
  final int index;
  const _PurchaseCard({required this.purchase, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(purchase.paymentStatus);
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    // Cycle each card's own background through pale tints of the same 5
    // colours used elsewhere (drawer icons, Companies/Employees/Sales/Customers lists).
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
      AppColors.brandBlack,
    ];
    final accent = accentColors[index % accentColors.length];
    final bg = Color.lerp(
      AppColors.surface,
      accent,
      AppColors.cardTintBlend(accent),
    )!;

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    final dividerColor = AppColors.ink.withValues(alpha: 0.12);

    return SwipeActions(
      onTap: () => _showPurchaseDetail(context, ref, purchase, accent),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () => context.push(
            AppRouter.createPurchase,
            extra: {'purchase': purchase, 'fromMasters': false},
          ),
        ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.brandBlack,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
      child: RichCardShell(
        accentColor: statusColor,
        backgroundColor: bg,
        backgroundGradient: AppColors.cardTintGradient(accent),
        showAccentBar: false,
        edgeColor: accent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient(accent),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                    ),
                    child: Text(
                      purchase.supplierName.trim().isNotEmpty
                          ? purchase.supplierName.trim()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.supplierName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: fgMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(purchase.billDate),
                              style: TextStyle(fontSize: 12, color: fgMuted),
                            ),
                            if (purchase.invoiceType != null) ...[
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: fgMuted)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  purchase.invoiceType!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: fgMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: fgMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              RichCardDivider(color: dividerColor),
              const SizedBox(height: 12),
              StatGrid(
                labelColor: fgMuted,
                valueColor: fg,
                dividerColor: dividerColor,
                items: [
                  StatGridItem(
                    label: 'Subtotal',
                    value: '₹${fmt.format(purchase.subtotal)}',
                  ),
                  StatGridItem(
                    label: 'Tax',
                    value: '₹${fmt.format(purchase.taxAmount)}',
                    color: AppColors.brand,
                  ),
                  StatGridItem(
                    label: 'Total',
                    value: '₹${fmt.format(purchase.totalAmount)}',
                    color: AppColors.positive,
                    bold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichCardDivider(color: dividerColor),
              const SizedBox(height: 10),
              _StatusChip(status: purchase.paymentStatus, color: statusColor),
            ],
          ),
        ),
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
        title: Text(
          'Delete Purchase',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete purchase from "${purchase.supplierName}"? This cannot be undone.',
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(purchasesProvider.notifier)
                    .deletePurchase(purchase.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.dangerFill,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.accentRose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => _purchaseStatusColor(status);
}

Color _purchaseStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return AppColors.accentEmerald;
    case 'pending':
      return AppColors.accentGold;
    case 'partial':
      return AppColors.accentIndigo;
    case 'cancelled':
      return AppColors.accentRose;
    default:
      return AppColors.accentSlate;
  }
}

void _showPurchaseDetail(
  BuildContext context,
  WidgetRef ref,
  Purchase purchase,
  Color accent,
) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final statusColor = _purchaseStatusColor(purchase.paymentStatus);
  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      avatarText: purchase.supplierName.trim().isNotEmpty
          ? purchase.supplierName.trim()[0].toUpperCase()
          : '?',
      avatarGradient: AppColors.accentGradient(accent),
      title: purchase.supplierName,
      subtitle: purchase.invoiceType,
      onEdit: () {
        Navigator.of(ctx).pop();
        ctx.push(
          AppRouter.createPurchase,
          extra: {'purchase': purchase, 'fromMasters': false},
        );
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Purchase',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            content: Text(
              'Delete purchase from "${purchase.supplierName}"? This cannot be undone.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await ref
              .read(purchasesProvider.notifier)
              .deletePurchase(purchase.id);
          if (ctx.mounted) Navigator.of(ctx).pop();
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.dangerFill,
              ),
            );
          }
        }
      },
      statusRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              purchase.paymentStatus,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '₹${fmt.format(purchase.totalAmount)}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      sections: [
        DetailSection(
          title: 'Invoice',
          items: [
            DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Bill Date',
              value: DateFormat('dd MMM yyyy').format(purchase.billDate),
            ),
            if (purchase.invoiceType != null)
              DetailRow(
                icon: Icons.description_outlined,
                label: 'Type',
                value: purchase.invoiceType!,
                iconColor: AppColors.positive,
              ),
            if (purchase.paymentType != null)
              DetailRow(
                icon: Icons.payments_outlined,
                label: 'Payment Method',
                value: purchase.paymentType!,
              ),
          ],
        ),
        DetailSection(
          title: 'Amount',
          items: [
            DetailRow(
              icon: Icons.receipt_outlined,
              label: 'Subtotal',
              value: '₹${fmt.format(purchase.subtotal)}',
            ),
            DetailRow(
              icon: Icons.percent_rounded,
              label: 'Tax',
              value: '₹${fmt.format(purchase.taxAmount)}',
              iconColor: AppColors.positive,
            ),
            DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total',
              value: '₹${fmt.format(purchase.totalAmount)}',
            ),
          ],
        ),
        if (purchase.notes != null && purchase.notes!.isNotEmpty)
          DetailSection(
            title: 'Notes',
            items: [
              DetailRow(
                icon: Icons.notes_rounded,
                label: 'Notes',
                value: purchase.notes!,
              ),
            ],
          ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    ),
  );
}
