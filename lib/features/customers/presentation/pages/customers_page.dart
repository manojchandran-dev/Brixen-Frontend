import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/customer.dart';
import '../providers/customers_provider.dart';

class CustomersPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const CustomersPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
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
    final customersAsync = ref.watch(customersProvider);

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: widget.fromMasters
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    Text('Customers', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customers', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
                  customersAsync.whenOrNull(
                    data: (list) => Text('${list.length} records',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                  ) ?? const SizedBox.shrink(),
                ],
              ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createCustomer,
                extra: widget.fromMasters ? 'masters' : null),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.silverGradient : null,
                color: isDark ? null : AppColors.lightTextPrimary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, size: 20,
                  color: isDark ? AppColors.black : AppColors.white),
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
                hintText: 'Search by name, phone or email…',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.silver : AppColors.lightTextPrimary,
                      width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text(e.toString(), style: TextStyle(color: cs.error, fontSize: 13))),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list.where((c) =>
                        c.name.toLowerCase().contains(q) ||
                        (c.phone?.toLowerCase().contains(q) ?? false) ||
                        (c.email?.toLowerCase().contains(q) ?? false)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No customers yet' : 'No results',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                        ),
                        if (list.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Tap + to add your first customer',
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CustomerCard(
                    customer: filtered[i],
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final bool isDark;
  const _CustomerCard({required this.customer, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push(AppRouter.customerDetail, extra: customer),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(
            children: [
              Container(width: 3, color: AppColors.accentGold),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      // Avatar circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface)),
                            if (customer.shopName != null) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.storefront_outlined, size: 11, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(customer.shopName!,
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              ]),
                            ],
                            if (customer.phone != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 11, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(customer.phone!,
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ],
                            if (customer.email != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 11, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(customer.email!,
                                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) => _onAction(context, ref, v),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(children: [
                              Icon(Icons.visibility_outlined, size: 16, color: cs.onSurface),
                              const SizedBox(width: 10),
                              Text('View', style: TextStyle(fontSize: 13, color: cs.onSurface)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 16, color: AppColors.accentIndigo),
                              const SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 13, color: AppColors.accentIndigo)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accentRose),
                              const SizedBox(width: 10),
                              Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.accentRose)),
                            ]),
                          ),
                        ],
                      ),
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

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'view':
        context.push(AppRouter.customerDetail, extra: customer);
      case 'edit':
        context.push(AppRouter.createCustomer, extra: customer);
      case 'delete':
        _confirmDelete(context, ref);
    }
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
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
