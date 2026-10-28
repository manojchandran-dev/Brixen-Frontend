import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final p = <String, String>{
      if (_search.isNotEmpty) 'search': _search,
      // A date filter becomes ?from=&to=.
      ...filterQueryParams(_filters),
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
        FilterSection.dates(key: 'days', title: 'Added'),
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
              skipError: true,
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
                      child: RefreshIndicator(
                        // Pull down to reload.
                        onRefresh: () => ref.refresh(customersProvider.future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _CustomerCard(customer: filtered[i], index: i),
                        ),
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
    // Accent colours rotate: each card's tint and avatar share one.
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
    ];
    final accent = accentColors[index % accentColors.length];

    final phone = customer.phone?.trim() ?? '';
    final gst = customer.gstNumber?.trim() ?? '';
    final shop = customer.shopName?.trim() ?? '';
    // Brand blue reads on light cards; its lighter tint on dark ones.
    final shopColor = AppColors.isDark ? AppColors.brandLight : AppColors.brand;

    // Avatar · name / highlighted shop name / phone & GST chips · call.
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
      // The same card as the other modules: tinted with its accent, with the
      // accent edge; opaque, so the swipe buttons stay hidden until swiped.
      child: RichCardShell(
        accentColor: accent,
        backgroundGradient: AppColors.cardTintGradient(accent),
        edgeColor: accent,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The shop name, highlighted.
                    if (shop.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: shopColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 15,
                              color: shopColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                shop,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: shopColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'No shop name',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (phone.isNotEmpty)
                          _InfoChip(
                            icon: Icons.call_rounded,
                            text: phone,
                            color: AppColors.textSecondary,
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
              if (phone.isNotEmpty)
                // One tap to call.
                IconButton(
                  tooltip: 'Call $phone',
                  onPressed: () => launchUrl(
                    Uri(scheme: 'tel', path: phone),
                  ).catchError((_) => false),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.positive.withValues(alpha: 0.15),
                  ),
                  icon: const Icon(
                    Icons.call_rounded,
                    size: 20,
                    color: AppColors.positive,
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
              _AddressBlock(address: customer.address!),
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
              // Stored in UTC; shown in the phone's time.
              value: DateFormat(
                'dd MMM yyyy · h:mm a',
              ).format(customer.createdAt.toLocal()),
            ),
          ],
        ),
      ],
    ),
  );
}

/// The address on its own full-width block (a long address squeezed
/// right-aligned next to its label is hard to read), with copy and map
/// shortcuts.
class _AddressBlock extends StatelessWidget {
  final String address;
  const _AddressBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    final lines = address
        .split(RegExp(r'[\n]+'))
        .map((l) => l.trim().replaceAll(RegExp(r',$'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.accentGradient(AppColors.brand),
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Address',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              lines.join('\n'),
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: address));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': lines.join(', '),
                  }),
                  mode: LaunchMode.externalApplication,
                ).catchError((_) => false),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Open in Maps'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
