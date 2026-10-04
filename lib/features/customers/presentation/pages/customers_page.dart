import 'dart:async';
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
import 'package:url_launcher/url_launcher.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/customer.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/search_field.dart';
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
    _debounce?.cancel();
    super.dispose();
  }

  // Filter sheet choices (null = All) and the search text — both go to the
  // API (see customerResultsProvider).
  Map<String, Object?> _filters = {};
  String _search = '';
  Timer? _debounce;

  /// Search + filters as API params, as a stable query string (the results
  /// provider's key). '' = neither → the full list. "days" → from/to.
  String _query() {
    final days = _filters['days'] as int?;
    final now = DateTime.now();
    final day = DateFormat('yyyy-MM-dd');
    final p = <String, String>{
      if (_search.isNotEmpty) 'search': _search,
      for (final e in _filters.entries)
        if (e.key != 'days' && e.value != null) e.key: '${e.value}',
      if (days != null) ...{
        'from': day.format(now.subtract(Duration(days: days - 1))),
        'to': day.format(now),
      },
    };
    final keys = p.keys.toList()..sort();
    return Uri(queryParameters: {for (final k in keys) k: p[k]!}).query;
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = v.trim());
    });
  }

  void _openFilter(List<Customer> all) {
    showChipFilterSheet(
      context,
      title: 'Filter customers',
      sections: [
        FilterSection(
          key: 'has_gst',
          title: 'GST',
          options: const [(true, 'Registered'), (false, 'Not registered')],
        ),
        FilterSection(
          key: 'days',
          title: 'Added',
          options: const [(7, 'Last 7 days'), (30, 'Last 30 days')],
        ),
      ],
      selected: _filters,
      onApply: (v) => setState(() => _filters = v),
      onClear: () => setState(() => _filters = {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _query();
    final customersAsync = query.isEmpty
        ? ref.watch(customersProvider)
        : ref.watch(customerResultsProvider(query));

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
          SearchFilterBar(
            controller: _searchCtrl,
            hintText: 'Search',
            onChanged: _onSearch,
            filterActive: _filters.values.any((v) => v != null),
            onFilter: () => _openFilter(customersAsync.valueOrNull ?? const []),
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
                  inline: true,
                ),
            ],
          ),
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: customersAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(customersProvider),
              ),
              data: (all) {
                final filtered = all;

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
                          query.isEmpty ? 'No customers yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (query.isEmpty) ...[
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
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _CustomerCard(customer: filtered[i], index: i),
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

/// Small tinted chip with an icon (phone, GST).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool strong;
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: strong ? color : AppColors.ink.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
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
    final bg = Color.lerp(
      AppColors.surface,
      accent,
      AppColors.cardTintBlend(accent),
    )!;
    final phone = customer.phone?.trim() ?? '';
    final gst = customer.gstNumber?.trim() ?? '';

    // Tinted card like the other module lists: avatar · name / shop /
    // phone & GST chips · call button.
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
      child: RichCardShell(
        accentColor: accent,
        backgroundColor: bg,
        backgroundGradient: AppColors.cardTintGradient(accent),
        edgeColor: accent,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                  boxShadow: AppColors.shadows([
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]),
                ),
                child: Text(
                  customer.name.trim().isNotEmpty
                      ? customer.name.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 17,
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
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 12,
                          color: fgMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            customer.shopName?.trim().isNotEmpty == true
                                ? customer.shopName!.trim()
                                : 'No shop name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: fgMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (phone.isNotEmpty)
                          // Tap the number to call.
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri(scheme: 'tel', path: phone),
                            ).catchError((_) => false),
                            child: _InfoChip(
                              icon: Icons.call_rounded,
                              text: phone,
                              color: accent,
                            ),
                          ),
                        _InfoChip(
                          icon: gst.isEmpty
                              ? Icons.remove_circle_outline_rounded
                              : Icons.verified_rounded,
                          text: gst.isEmpty ? 'No GST' : gst,
                          color: gst.isEmpty
                              ? AppColors.textHint
                              : AppColors.positive,
                          strong: gst.isNotEmpty,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
