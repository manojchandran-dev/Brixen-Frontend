import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../../companies/presentation/widgets/company_filter_sheet.dart';
import '../providers/permissions_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

/// List of companies with their module-access summary — same list/create/
/// edit/delete shape as every other module (Products, Employees, ...).
/// Reachable from the drawer's "Permissions" item.
class PermissionManagementPage extends ConsumerStatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  ConsumerState<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState
    extends ConsumerState<PermissionManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GET /permissions/companies: search, filters, paging and each
    // company's Full/Custom/None counts all come from the server.
    final resultsAsync = ref.watch(permissionCompaniesProvider);
    final page = resultsAsync.valueOrNull;
    final filters = ref.watch(permissionFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      // AppBottomNav fills the Scaffold height (its pill is Align-ed to the
      // bottom) — without extendBody the body gets zero height.
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Icon(Icons.menu_rounded, color: AppColors.ink),
          ),
        ),
        title: ModuleTitle(
          title: 'Permissions',
          subtitle: 'Module access for each company',
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createPermission),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.brand),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        ref.read(permissionSearchProvider.notifier).state = v;
                        setState(() {}); // show/hide the ✕
                      },
                      style: TextStyle(color: AppColors.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search company…',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                                onPressed: () => setState(() {
                                  _searchCtrl.clear();
                                  ref
                                          .read(
                                            permissionSearchProvider.notifier,
                                          )
                                          .state =
                                      '';
                                }),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                HeaderIconButton(
                  tooltip: 'Filter companies',
                  icon: Icons.filter_list_rounded,
                  active: filters.count > 0,
                  onTap: () => showCompanyFilterSheet(
                    context,
                    initial: filters,
                    companies: page?.items ?? const [],
                    serverOptions: page?.counts ?? const {},
                    onApply: (f) =>
                        ref.read(permissionFiltersProvider.notifier).state = f,
                    onClear: () {
                      ref.read(permissionFiltersProvider.notifier).state =
                          const CompanyFilters();
                      ref.invalidate(permissionCompaniesProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
          ListCountBar(label: 'Total Companies', count: page?.total ?? 0),
          Expanded(
            child: page == null
                // First load: skeleton, or the error if it failed.
                ? (resultsAsync.hasError && !resultsAsync.isLoading
                      ? ErrorCard(
                          error: resultsAsync.error!,
                          onRetry: () =>
                              ref.invalidate(permissionCompaniesProvider),
                        )
                      : const SkeletonListView())
                // A search/filter/refresh in flight: skeleton; the search
                // box above stays usable.
                : resultsAsync.isLoading
                ? const SkeletonListView()
                : page.items.isEmpty
                ? Center(
                    child: Text(
                      resultsAsync.hasError
                          ? resultsAsync.error.toString()
                          : filters.count > 0
                          ? 'No companies match these filters'
                          : _searchCtrl.text.trim().isNotEmpty
                          ? 'No results'
                          : 'No companies yet',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14),
                    ),
                  )
                // Near the bottom → fetch the next page of 50.
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (page.items.length < page.total &&
                          n.metrics.extentAfter < 400) {
                        ref
                            .read(permissionCompaniesProvider.notifier)
                            .loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount:
                          page.items.length +
                          (page.items.length < page.total ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => i == page.items.length
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : _CompanyPermissionCard(
                              company: page.items[i],
                              index: i,
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompanyPermissionCard extends ConsumerWidget {
  final Company company;
  final int index;
  const _CompanyPermissionCard({required this.company, this.index = 0});

  // Same accent cycle as the Employees / Products cards.
  static const _accents = [
    AppColors.brand,
    AppColors.positive,
    AppColors.brandDeep,
    AppColors.brandLight,
    AppColors.brandBlack,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // From GET /permissions/companies — no per-company request.
    final access = company.access ?? const AccessCounts();
    final fullCount = access.full;
    final customCount = access.custom;
    final noneCount = access.none;
    final total = access.total;
    final accent = _accents[index % _accents.length];

    return SwipeActions(
      onTap: () => context.push(AppRouter.createPermission, extra: company),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.brand,
          onTap: () => context.push(AppRouter.createPermission, extra: company),
        ),
        SwipeAction(
          icon: Icons.restore_outlined,
          label: 'Delete',
          color: AppColors.brandBlack,
          onTap: () => _confirmReset(context, ref),
        ),
      ],
      child: RichCardShell(
        accentColor: accent,
        backgroundColor: Color.lerp(
          AppColors.surface,
          accent,
          AppColors.cardTintBlend(accent),
        ),
        backgroundGradient: AppColors.cardTintGradient(accent),
        edgeColor: accent,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                    ),
                    child: Text(
                      company.initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.ink.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                company.ownerName.isEmpty
                                    ? 'No owner'
                                    : company.ownerName,
                                style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Access at a glance: one segment per level, sized by count.
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        if (fullCount > 0)
                          Expanded(
                            flex: fullCount,
                            child: Container(color: AppColors.positive),
                          ),
                        if (customCount > 0)
                          Expanded(
                            flex: customCount,
                            child: Container(color: AppColors.brand),
                          ),
                        if (noneCount > 0)
                          Expanded(
                            flex: noneCount,
                            child: Container(
                              color: AppColors.textHint.withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _CountChip(
                    icon: Icons.verified_user_rounded,
                    count: fullCount,
                    label: 'Full',
                    color: AppColors.positive,
                  ),
                  const SizedBox(width: 6),
                  _CountChip(
                    icon: Icons.tune_rounded,
                    count: customCount,
                    label: 'Custom',
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: 6),
                  _CountChip(
                    icon: Icons.block_rounded,
                    count: noneCount,
                    label: 'None',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Permissions',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Clear every saved permission for "${company.name}"? The company will lose access to all modules except Support Ticket and Chatbot until you grant them again.',
          style: TextStyle(color: AppColors.textHint, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dCtx).pop();
              try {
                await ref
                    .read(permissionsProvider(company.id).notifier)
                    .reset();
              } catch (e) {
                if (context.mounted) showErrorDialog(context, e);
              }
            },
            child: Text(
              'Reset',
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

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  const _CountChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
