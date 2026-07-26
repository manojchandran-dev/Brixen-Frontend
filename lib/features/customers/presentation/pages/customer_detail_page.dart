import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/customer.dart';
import '../providers/customers_provider.dart';

class CustomerDetailPage extends ConsumerWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightTextPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
            Text('Customer',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createCustomer, extra: customer),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.edit_outlined, size: 18, color: AppColors.accentIndigo),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Avatar hero card
          _SectionCard(
            isDark: isDark,
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accentGold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      if (customer.shopName != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.storefront_outlined, size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(customer.shopName!,
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ]),
                      ],
                      if (customer.gstNumber != null) ...[
                        const SizedBox(height: 3),
                        Text('GST: ${customer.gstNumber!}',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Contact info
          if (customer.phone != null || customer.email != null)
            _SectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  if (customer.phone != null) ...[
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: customer.phone!,
                    ),
                    if (customer.email != null) _DividerLine(),
                  ],
                  if (customer.email != null)
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: customer.email!,
                    ),
                ],
              ),
            ),

          if (customer.phone != null || customer.email != null)
            const SizedBox(height: 14),

          // Address
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(customer.address!,
                            style: TextStyle(fontSize: 14, color: cs.onSurface)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Meta
          _SectionCard(
            isDark: isDark,
            child: _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(customer.createdAt),
            ),
          ),
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
        title: Text('Delete Customer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Delete "${customer.name}"? This cannot be undone.',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              ref.read(customersProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
              context.go(AppRouter.customers);
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }
}
