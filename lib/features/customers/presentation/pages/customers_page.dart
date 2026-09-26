import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/deleted_items_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/super_admin_company_filter_bar.dart';
import 'package:intl/intl.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/customer.dart';
import '../providers/customers_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

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
                      'Customers',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ModuleTitle(
                title: 'Customers',
                subtitle: 'Your customer records',
              ),
        actions: [
          if (ref.watch(moduleAccessProvider('Customers')).delete)
            DeletedItemsButton(
              title: 'Deleted customers',
              listPath: ApiEndpoints.customers,
              restorePath: (c) =>
                  '${ApiEndpoints.customers}/${c['id']}/restore',
              labelOf: (c) => (c['name'] ?? '').toString(),
              subtitleOf: (c) => (c['shop_name'] ?? c['phone']) as String?,
              onRestored: () => ref.invalidate(customersProvider),
            ),
          if (ref.watch(moduleAccessProvider('Customers')).create)
            GestureDetector(
              onTap: () => context.push(
                AppRouter.createCustomer,
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
                  hintText: 'Search by name, phone or email…',
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
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: customersAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(customersProvider),
              ),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(q) ||
                                (c.phone?.toLowerCase().contains(q) ?? false) ||
                                (c.email?.toLowerCase().contains(q) ?? false),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No customers yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (list.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add your first customer',
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

                // A single rounded card holding every row (dividers between,
                // no per-row shadow) — same flat list style as Employees.
                return Column(
                  children: [
                    ListCountBar(
                      label: 'Total Customers',
                      count: filtered.length,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.shadows([
                                BoxShadow(
                                  color: AppColors.shadowDark.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: AppColors.highlightShadow(0.85),
                                  blurRadius: 6,
                                  offset: const Offset(-3, -3),
                                ),
                              ]),
                            ),
                            child: Column(
                              children: filtered.asMap().entries.map((entry) {
                                final i = entry.key;
                                return Column(
                                  children: [
                                    _CustomerCard(
                                      customer: entry.value,
                                      index: i,
                                    ),
                                    if (i != filtered.length - 1)
                                      Divider(
                                        height: 1,
                                        color: AppColors.border,
                                        indent: 59,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  final int index;
  const _CustomerCard({required this.customer, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
      AppColors.brandBlack,
    ];
    final accent = accentColors[index % accentColors.length];

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.55);
    final fgFaint = AppColors.ink.withValues(alpha: 0.4);

    // Flat list row — avatar, name, shop name and GST only — matching the
    // Employees list style, instead of an individually shadowed card.
    return SwipeActions(
      onTap: () => _showCustomerDetail(context, ref, customer, accent),
      actions: [
        if (ref.watch(moduleAccessProvider('Customers')).edit)
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () =>
                context.push(AppRouter.createCustomer, extra: customer),
          ),
        if (ref.watch(moduleAccessProvider('Customers')).delete)
          SwipeAction(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.brandBlack,
            onTap: () => _confirmDelete(context, ref),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.accentGradient(accent),
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                customer.name.trim().isNotEmpty
                    ? customer.name.trim()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.shopName ?? '—',
                    style: TextStyle(fontSize: 12, color: fgMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.gstNumber ?? 'No GST',
                    style: TextStyle(fontSize: 11, color: fgFaint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
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
          'Delete Customer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete "${customer.name}"? This cannot be undone.',
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
                    .read(customersProvider.notifier)
                    .deleteCustomer(
                      customer.id,
                      companyId: Session.isSuperAdmin
                          ? customer.companyId
                          : null,
                    );
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
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showCustomerDetail(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
  Color accent,
) {
  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      avatarText: customer.name.trim().isNotEmpty
          ? customer.name.trim()[0].toUpperCase()
          : '?',
      avatarGradient: AppColors.accentGradient(accent),
      title: customer.name,
      subtitle: customer.shopName,
      onEdit: !ref.read(moduleAccessProvider('Customers')).edit
          ? null
          : () {
              Navigator.of(ctx).pop();
              ctx.push(AppRouter.createCustomer, extra: customer);
            },
      onDelete: !ref.read(moduleAccessProvider('Customers')).delete
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Delete Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  content: Text(
                    'Delete "${customer.name}"? This cannot be undone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
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
                    .read(customersProvider.notifier)
                    .deleteCustomer(
                      customer.id,
                      companyId: Session.isSuperAdmin
                          ? customer.companyId
                          : null,
                    );
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
      sections: [
        DetailSection(
          title: 'Contact',
          items: [
            if (customer.phone != null)
              DetailRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: customer.phone!,
              ),
            if (customer.email != null)
              DetailRow(
                icon: Icons.mail_rounded,
                label: 'Email',
                value: customer.email!,
                iconColor: AppColors.positive,
              ),
            if (customer.address != null && customer.address!.isNotEmpty)
              DetailRow(
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: customer.address!,
              ),
          ],
        ),
        DetailSection(
          title: 'Business',
          items: [
            if (customer.shopName != null)
              DetailRow(
                icon: Icons.storefront_rounded,
                label: 'Shop Name',
                value: customer.shopName!,
              ),
            DetailRow(
              icon: Icons.receipt_long_rounded,
              label: 'GST No',
              value: customer.gstNumber ?? 'No GST',
              iconColor: AppColors.positive,
            ),
            DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Added',
              value: DateFormat('dd MMM yyyy').format(customer.createdAt),
            ),
          ],
        ),
      ],
    ),
  );
}
