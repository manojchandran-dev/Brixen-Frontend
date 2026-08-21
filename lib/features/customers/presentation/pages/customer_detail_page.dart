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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Delete "${customer.name}"? This cannot be undone.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
                if (context.mounted) context.go(AppRouter.customers);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(-2, -2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Customers', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
              Flexible(child: Text(customer.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))),
            ]),
          ),
          const Text('Customer', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createCustomer, extra: customer),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Profile hero card ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Text(
                    customer.name.trim().isNotEmpty ? customer.name.trim()[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      if (customer.shopName != null) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.storefront_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(customer.shopName!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ]),
                      ],
                      if (customer.gstNumber != null) ...[
                        const SizedBox(height: 3),
                        Text('GST: ${customer.gstNumber!}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Contact info ───────────────────────────────────────────
          if (customer.phone != null || customer.email != null) ...[
            _SectionCard(child: Column(
              children: [
                if (customer.phone != null) ...[
                  _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: customer.phone!, accentColor: AppColors.brand),
                  if (customer.email != null) _DividerLine(),
                ],
                if (customer.email != null)
                  _DetailRow(icon: Icons.mail_rounded, label: 'Email', value: customer.email!, accentColor: AppColors.positive),
              ],
            )),
            const SizedBox(height: 18),
          ],

          // ── Address ────────────────────────────────────────────────
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            _SectionTitle('Address', icon: Icons.location_on_rounded, color: AppColors.brandDeep),
            const SizedBox(height: 10),
            _SectionCard(child: _DetailRow(icon: Icons.location_on_rounded, label: 'Address', value: customer.address!, accentColor: AppColors.brandDeep)),
            const SizedBox(height: 18),
          ],

          // ── Meta ───────────────────────────────────────────────────
          _SectionCard(child: _DetailRow(icon: Icons.history_rounded, label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(customer.createdAt), accentColor: AppColors.brandLight)),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionTitle(this.title, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22, height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 12, color: color),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
    ]);
  }
}

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
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
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
  final Color accentColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.accentColor = AppColors.brand});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentColor, accentColor.withValues(alpha: 0.75)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textHint)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
