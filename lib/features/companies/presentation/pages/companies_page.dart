import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../domain/entities/company.dart';
import '../providers/companies_provider.dart';
import '../widgets/company_card.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/welcome_dashboard_view.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/domain/entities/master_type.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../../masters/presentation/cubit/master_state.dart';
// Attendance module disabled for now — uncomment to re-enable.
// import '../../../attendance/presentation/pages/attendance_body.dart';

class CompaniesPage extends StatelessWidget {
  final String? initialSection;
  const CompaniesPage({super.key, this.initialSection});

  @override
  Widget build(BuildContext context) {
    return _CompaniesView(initialSection: initialSection);
  }
}

class _CompaniesView extends ConsumerStatefulWidget {
  final String? initialSection;
  const _CompaniesView({this.initialSection});

  @override
  ConsumerState<_CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends ConsumerState<_CompaniesView> {
  final _searchCtrl = TextEditingController();
  int _navIndex = 0;

  // Navigation stack for Menu tab
  // e.g. [] = menu home, ['companies'] = companies list,
  //      ['masters'] = masters, ['masters','companyCategory'] = cat list,
  //      ['masters','companyCategory','create'] = create form,
  //      ['masters','companyCategory','edit:id'] = edit form
  final List<String> _stack = [];

  bool get _inMenuSub => _navIndex == 3 && _stack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialSection != null) {
      _navIndex = 3;
      _stack.addAll(widget.initialSection!.split('/'));
    }
  }

  @override
  void didUpdateWidget(covariant _CompaniesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // GoRouter reuses this State when navigating to the same `/companies`
    // route with new `extra` (e.g. re-tapping a drawer item while already
    // here) — initState() won't run again, so re-apply the section here.
    if (widget.initialSection != null && widget.initialSection != oldWidget.initialSection) {
      setState(() {
        _navIndex = 3;
        _stack
          ..clear()
          ..addAll(widget.initialSection!.split('/'));
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int i) => setState(() { _navIndex = i; _stack.clear(); });

  bool get _hideNavBar {
    if (_stack.isEmpty) return false;
    final last = _stack.last;
    return last == 'create' || last.startsWith('edit:');
  }

  // For masterMenu drill-down: masters/masterMenu/cat:<catId>
  bool get _inCategoryDrillDown =>
      _stack.length >= 3 && _stack[0] == 'masters' && _stack[1] == 'masterMenu' && _stack[2].startsWith('cat:');
  String get _drillCatId => _inCategoryDrillDown ? _stack[2].substring(4) : '';
  void _push(String page) => setState(() => _stack.add(page));
  void _pop() => setState(() { if (_stack.isNotEmpty) _stack.removeLast(); });
  void _popTo(int depth) => setState(() { while (_stack.length > depth) { _stack.removeLast(); } });

  // ── AppBar ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_inMenuSub,
      onPopInvokedWithResult: (didPop, _) { if (!didPop && _inMenuSub) _pop(); },
      child: BlocProvider.value(
        value: masterCubit,
        child: Scaffold(
          extendBody: true,
          drawer: _inMenuSub ? null : const AppDrawer(),
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Theme.of(context).dividerColor),
            ),
            leading: Builder(
              builder: (ctx) => Center(
                child: Material(
                  color: isDark ? AppColors.surface : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  shadowColor: AppColors.ink.withValues(alpha: 0.3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _inMenuSub ? _pop : () => Scaffold.of(ctx).openDrawer(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        _inMenuSub ? Icons.arrow_back_ios_new_rounded : Icons.menu_rounded,
                        size: _inMenuSub ? 16 : 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: _inMenuSub
                ? _buildBreadcrumb(cs)
                : Text(
                    _navLabel(_navIndex),
                    style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
            actions: [_buildAction(cs, isDark)],
          ),
          body: _buildBody(),
          bottomNavigationBar: _hideNavBar ? null : _BottomNav(currentIndex: _navIndex, onTap: _onNavTap),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(ColorScheme cs) {
    final crumbs = <_Crumb>[_Crumb('More', () => _popTo(0))];
    for (int i = 0; i < _stack.length; i++) {
      final seg = _stack[i];
      final depth = i + 1;
      final isLast = i == _stack.length - 1;
      final label = _segLabel(seg);
      // 'masters' has no standalone page of its own anymore — it's just a
      // breadcrumb label, not a tappable stop, since every drawer link now
      // goes straight to a specific master type (companyCategory/etc).
      final tappable = !isLast && seg != 'masters';
      crumbs.add(_Crumb(label, tappable ? () => _popTo(depth) : null));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: crumbs.expand((c) sync* {
          if (crumbs.indexOf(c) > 0) {
            yield Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded, size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            );
          }
          yield GestureDetector(
            onTap: c.onTap,
            child: Text(c.label, style: TextStyle(
              color: c.onTap != null
                  ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                  : cs.onSurface,
              fontSize: c.onTap != null ? 12 : 15,
              fontWeight: c.onTap != null ? FontWeight.w400 : FontWeight.w700,
              letterSpacing: c.onTap == null ? 0.1 : 0,
            )),
          );
        }).toList(),
      ),
    );
  }

  String _segLabel(String seg) {
    if (seg == 'companies') return 'Companies';
    if (seg == 'masters') return 'Masters';
    if (seg == 'create') return 'Create';
    if (seg.startsWith('edit:')) return 'Edit';
    if (seg.startsWith('cat:')) {
      // Resolve category name from any item that has this category
      final catId = seg.substring(4);
      final s = masterCubit.state;
      if (s is MasterLoaded) {
        try {
          return s.items.firstWhere((x) => x.assignedCategoryId == catId).assignedCategoryName ?? catId;
        } catch (_) {}
      }
      return catId;
    }
    return masterTypeFor(seg)?.name ?? seg;
  }

  Widget _buildAction(ColorScheme cs, bool isDark) {
    final last = _stack.isEmpty ? '' : _stack.last;
    VoidCallback? onTap;
    if (last == 'companies') onTap = () => context.push(AppRouter.createCompany, extra: 'menu');
    // masterMenu top-level category view or drilled-into category: + opens create
    if (last == 'masterMenu') onTap = () => _push('create');
    if (last.startsWith('cat:')) onTap = () => _push('create');
    // Other non-assignable master types: + opens create
    if (masterTypeFor(last) != null && !(masterTypeFor(last)?.hasParentAssignment ?? false)) {
      onTap = () => _push('create');
    }
    if (onTap == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        margin: const EdgeInsets.only(right: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.silverGradient : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: isDark ? 0.0 : 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(Icons.add_rounded, size: 20, color: isDark ? AppColors.black : AppColors.white),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_navIndex == 3 && _stack.isNotEmpty) {
      final path = _stack.join('/');
      if (path == 'companies') return _CompaniesListBody(searchCtrl: _searchCtrl);

      // ── masterMenu: 2-level drill-down ──────────────────────────────────────
      if (path == 'masters/masterMenu') {
        return _MasterMenuCategoryView(onCategoryTap: (catId) => _push('cat:$catId'));
      }
      // masters/masterMenu/cat:<catId> → items for that category
      if (_inCategoryDrillDown && _stack.length == 3) {
        return _MasterItemsBody(
          typeKey: 'masterMenu',
          filterCategoryId: _drillCatId,
          onEdit: (id) => _push('edit:$id'),
        );
      }
      // masters/masterMenu/cat:<catId>/create
      if (_inCategoryDrillDown && _stack.length == 4 && _stack.last == 'create') {
        return _MasterFormBody(typeKey: 'masterMenu', defaultCategoryId: _drillCatId, onSaved: _pop);
      }
      // masters/masterMenu/cat:<catId>/edit:<id>
      if (_inCategoryDrillDown && _stack.length == 4 && _stack.last.startsWith('edit:')) {
        return _MasterFormBody(typeKey: 'masterMenu', editId: _stack.last.substring(5), onSaved: _pop);
      }

      // ── Generic master types ─────────────────────────────────────────────────
      if (_stack.length == 2 && _stack[0] == 'masters') {
        return _MasterItemsBody(typeKey: _stack[1], onEdit: (id) => _push('edit:$id'));
      }
      if (_stack.length == 3 && _stack[0] == 'masters' && _stack[2] == 'create') {
        return _MasterFormBody(typeKey: _stack[1], onSaved: _pop);
      }
      if (_stack.length == 3 && _stack[0] == 'masters' && _stack[2].startsWith('edit:')) {
        return _MasterFormBody(typeKey: _stack[1], editId: _stack[2].substring(5), onSaved: _pop);
      }
    }
    switch (_navIndex) {
      case 0:
        return const WelcomeDashboardView();
      // Attendance module disabled for now — uncomment to re-enable.
      // case 1: return const AttendanceBody();
      case 2:
        return const ComingSoonView(
          icon: Icons.bar_chart_rounded,
          title: 'Reports',
          subtitle: 'Company-wide reports are on the way.',
        );
      case 3: return const _MenuBody();
      default: return const SizedBox.shrink();
    }
  }

  String _navLabel(int i) => ['Dashboard', 'Attendance', 'Reports', 'More'][i];
}

class _Crumb {
  final String label;
  final VoidCallback? onTap;
  _Crumb(this.label, this.onTap);
}

// ── Companies list (opened from Menu tab) ────────────────────────────────────

class _CompaniesListBody extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _CompaniesListBody({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);
    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.silver)),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      data: (companies) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                          BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
                        ],
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        style: const TextStyle(color: AppColors.ink, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
                          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onChanged: (v) => ref.read(companiesProvider.notifier).search(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46, height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                        BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.brand, size: 19),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Companies', style: TextStyle(color: AppColors.textHint, fontSize: 12.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(companies.length.toString(),
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: companies.isEmpty
                  ? Center(child: Text('No companies found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: companies.length,
                      itemBuilder: (context, i) {
                        final c = companies[i];
                        return CompanyCard(
                          company: c,
                          index: i,
                          onToggleStatus: () {
                            ref.read(companiesProvider.notifier).toggleStatus(c.id).then((err) {
                              if (err != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err), backgroundColor: AppColors.ink),
                                );
                              }
                            });
                          },
                          onDelete: () => ref.read(companiesProvider.notifier).deleteCompany(c.id),
                          onView: () => _viewCompanyDetail(context, ref, c.id),
                          onEdit: () => context.push(AppRouter.createCompany, extra: {'edit': c}),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Company detail sheet ──────────────────────────────────────────────────────

Future<void> _viewCompanyDetail(BuildContext context, WidgetRef ref, String id) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.silver)),
  );
  try {
    final company = await ref.read(companiesProvider.notifier).fetchCompanyDetail(id);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showCompanyDetail(context, ref, company);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
    );
  }
}

void _showCompanyDetail(BuildContext context, WidgetRef ref, Company company) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      behavior: HitTestBehavior.opaque,
      child: _CompanyDetailSheet(
        company: company,
        onEdit: () {
          Navigator.of(ctx).pop();
          ctx.push(AppRouter.createCompany, extra: {'edit': company});
        },
        onDelete: () async {
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (dCtx) => AlertDialog(
              title: const Text('Delete company?'),
              content: Text('This will permanently remove "${company.name}". This can\'t be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.of(dCtx).pop(true),
                  child: const Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(companiesProvider.notifier).deleteCompany(company.id);
            if (ctx.mounted) Navigator.of(ctx).pop();
          }
        },
        onToggleStatus: () async {
          final err = await ref.read(companiesProvider.notifier).toggleStatus(company.id);
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.ink));
            }
          }
        },
      ),
    ),
  );
}

class _CompanyDetailSheet extends StatelessWidget {
  final Company company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  const _CompanyDetailSheet({
    required this.company,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = company; // Company — all fields are typed with null safety
    final isPending = c.onboardingStatus != null && c.onboardingStatus != 'completed';
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => GestureDetector(
        onTap: () {}, // absorb taps so the outer dismiss handler ignores sheet touches
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brand, AppColors.brandDeep],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      child: Text(c.initials, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                          if (c.industryType != null)
                            Text(c.industryType!, style: const TextStyle(color: AppColors.textHint, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SheetIconButton(icon: Icons.edit_outlined, color: AppColors.brand, onTap: onEdit),
                    const SizedBox(width: 8),
                    _SheetIconButton(icon: Icons.delete_outline_rounded, color: AppColors.ink, onTap: onDelete),
                  ],
                ),
              ),
              // Status row — tap to toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onToggleStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: c.isActive ? AppColors.positive : AppColors.ink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(c.isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded, color: AppColors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(c.isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text('Tap to ${c.isActive ? 'deactivate' : 'activate'}',
                                  style: const TextStyle(color: AppColors.white, fontSize: 11.5, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              const Icon(Icons.sync_alt_rounded, color: AppColors.white, size: 15),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(16)),
                        child: const Text('Setup Pending', style: TextStyle(color: AppColors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
              // Details list
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                  children: [
                    _DetailSection(title: 'Contact Information', items: [
                      if (c.ownerName.isNotEmpty)
                        _DetailRow(icon: Icons.person_outline, label: 'Owner', value: c.ownerName),
                      if (c.email != null && c.email!.isNotEmpty)
                        _DetailRow(icon: Icons.mail_outline_rounded, label: 'Email', value: c.email!, iconColor: AppColors.positive),
                      if (c.phone != null && c.phone!.isNotEmpty)
                        _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: c.phone!),
                    ]),
                    const SizedBox(height: 18),
                    _DetailSection(title: 'Location', items: [
                      if (c.address != null)  _DetailRow(icon: Icons.location_on_outlined,   label: 'Address', value: c.address!, iconColor: AppColors.positive),
                      if (c.city != null)     _DetailRow(icon: Icons.location_city_outlined, label: 'City',    value: c.city!),
                      if (c.state != null)    _DetailRow(icon: Icons.map_outlined,           label: 'State',   value: c.state!, iconColor: AppColors.positive),
                      if (c.country != null)  _DetailRow(icon: Icons.language_outlined,      label: 'Country', value: c.country!),
                      if (c.pincode != null)  _DetailRow(icon: Icons.pin_outlined,           label: 'Pincode', value: c.pincode!, iconColor: AppColors.positive),
                    ]),
                    const SizedBox(height: 18),
                    _DetailSection(title: 'Business', items: [
                      if (c.industryType != null)     _DetailRow(icon: Icons.work_outline,             label: 'Industry',     value: c.industryType!),
                      if (c.subscriptionPlan != null) _DetailRow(icon: Icons.card_membership_outlined, label: 'Plan',         value: c.subscriptionPlan!, iconColor: AppColors.positive),
                      _DetailRow(icon: Icons.calendar_today_outlined, label: 'Created', value: '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SheetIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _DetailSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-2, -2)),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) => Column(
              children: [
                e.value,
                if (e.key < items.length - 1) const Divider(height: 1, color: AppColors.border, indent: 60),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.iconColor = AppColors.brand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [iconColor, iconColor.withValues(alpha: 0.75)],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}


// ── Menu full page ────────────────────────────────────────────────────────────

class _MenuBody extends StatelessWidget {
  const _MenuBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ── Premium profile card ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.brand, AppColors.positive],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: const Center(
                  child: Text('AD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.white)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    SizedBox(height: 6),
                    _RoleBadge(),
                  ],
                ),
              ),
              Container(
                width: 34, height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.white, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // ── Preferences ───────────────────────────────────────────
        _MenuSectionLabel('Preferences'),
        const SizedBox(height: 10),
        _MenuSection(items: [
          _MenuItem(icon: Icons.settings_rounded, label: 'Settings', color: AppColors.brand,    onTap: () => context.push(AppRouter.security)),
          _MenuItem(icon: Icons.help_rounded,     label: 'Support',  color: AppColors.positive, onTap: () {}),
        ]),
        const SizedBox(height: 24),

        // ── Logout ────────────────────────────────────────────────
        GestureDetector(
          onTap: () async {
            await authCubit.signOut();
            if (context.mounted) context.go(AppRouter.signIn);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(-4, -4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                const Text('Logout', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink.withValues(alpha: 0.35), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // ── Footer ────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Brix', style: TextStyle(color: AppColors.brand)),
                  const TextSpan(text: 'en', style: TextStyle(color: AppColors.positive)),
                ]),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
              const SizedBox(height: 4),
              const Text('Version 1.0.0', style: TextStyle(color: AppColors.textHint, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_rounded, size: 12, color: AppColors.white),
        SizedBox(width: 4),
        Text('Super Admin', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MenuSectionLabel extends StatelessWidget {
  final String label;
  const _MenuSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 13, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(-4, -4)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: 14),
                      Text(item.label,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.ink.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, color: AppColors.border, indent: 66),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap});
}

// ── Floating pill bottom nav ──────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // NOTE: no transparent ColoredBox wrapper here — with `extendBody: true`
    // this widget is stretched to the full Scaffold height, and a
    // Container(color: ...) — even fully transparent — always intercepts
    // hit-testing across its whole bounds, silently swallowing every tap
    // (including the AppBar's hamburger) outside the actual nav pill.
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavBtn(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, isActive: currentIndex == 0, onTap: () => onTap(0)),
              // Attendance module disabled for now — uncomment to re-enable.
              // _NavBtn(icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled_rounded, isActive: currentIndex == 1, onTap: () => onTap(1)),
              _NavBtn(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, isActive: currentIndex == 2, onTap: () => onTap(2)),
              _NavBtn(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, isActive: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.activeIcon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Black pill bar, active icon shown inside a filled green circle.
    final iconColor = isActive ? AppColors.white : Colors.white.withValues(alpha: 0.5);

    return SizedBox(
      width: 50,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive ? AppColors.positive : null,
              shape: BoxShape.circle,
            ),
            child: Icon(isActive ? activeIcon : icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}



// ── Masters List ─────────────────────────────────────────────────────────────

// Individual item cards within a master list cycle through the full 5-color
// brand palette by index (same pattern as the Companies list) instead of all
// sharing one flat color per master type.
const _masterCardAccentColors = [AppColors.brand, AppColors.positive, AppColors.brandDeep, AppColors.brandLight, AppColors.ink];

// ── Generic Master Items List ─────────────────────────────────────────────────

class _MasterItemsBody extends StatefulWidget {
  final String typeKey;
  final void Function(String id) onEdit;
  final String? filterCategoryId; // null = show all
  const _MasterItemsBody({required this.typeKey, required this.onEdit, this.filterCategoryId});
  @override
  State<_MasterItemsBody> createState() => _MasterItemsBodyState();
}

class _MasterItemsBodyState extends State<_MasterItemsBody> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory; // null = All

  bool get _hasCategories => masterTypeFor(widget.typeKey)?.hasParentAssignment ?? false;

  @override
  void initState() {
    super.initState();
    masterCubit.load(widget.typeKey);
  }

  @override
  void didUpdateWidget(covariant _MasterItemsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No Key on this widget, so Flutter reuses this State when navigating
    // between different master types in the same slot — initState won't
    // re-run, so reload explicitly when the type actually changes.
    if (oldWidget.typeKey != widget.typeKey || oldWidget.filterCategoryId != widget.filterCategoryId) {
      masterCubit.load(widget.typeKey);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeCfg = masterTypeFor(widget.typeKey);
    return BlocBuilder<MasterCubit, MasterState>(
      bloc: masterCubit,
      builder: (context, state) {
        if (state is MasterError) {
          return Center(child: Text(state.message, style: TextStyle(color: cs.onSurfaceVariant)));
        }
        if (state is! MasterLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.silver));
        }

        // Build unique category list from all items (not just filtered)
        final allItems = state.items;
        final categoryMap = <String, String>{}; // id → name
        for (final item in allItems) {
          if (item.assignedCategoryId != null && item.assignedCategoryName != null) {
            categoryMap[item.assignedCategoryId!] = item.assignedCategoryName!;
          }
        }

        // Apply category filter: prop-level filter takes priority over chip selection
        final items = state.filtered.where((item) {
          final catFilter = widget.filterCategoryId ?? _selectedCategory;
          if (catFilter == null) return true;
          return item.assignedCategoryId == catFilter;
        }).toList();

        // Count per category (for badge)
        final countMap = <String, int>{};
        for (final item in state.items) {
          if (item.assignedCategoryId != null) {
            countMap[item.assignedCategoryId!] = (countMap[item.assignedCategoryId!] ?? 0) + 1;
          }
        }

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                    BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search ${typeCfg?.name ?? 'items'}...',
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onChanged: masterCubit.search,
                ),
              ),
            ),

            // Category filter chips (only for assignable types)
            if (_hasCategories && categoryMap.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: allItems.length,
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...categoryMap.entries.map((e) => _FilterChip(
                      label: e.value,
                      count: countMap[e.key] ?? 0,
                      selected: _selectedCategory == e.key,
                      onTap: () => setState(() => _selectedCategory = e.key),
                    )),
                  ],
                ),
              ),

            if (_hasCategories && categoryMap.isNotEmpty)
              const SizedBox(height: 4),

            // List
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('No items found', style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final itemColor = _masterCardAccentColors[i % _masterCardAccentColors.length];
                        return _MasterCard(
                        item: items[i],
                        icon: typeCfg?.icon ?? Icons.list_alt_outlined,
                        color: itemColor,
                        onView: () => _showMasterDetail(
                          context,
                          items[i],
                          typeCfg?.icon ?? Icons.list_alt_outlined,
                          itemColor,
                        ),
                        onEdit: () => widget.onEdit(items[i].id),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                              title: Text('Delete ${typeCfg?.name ?? 'item'}?',
                                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
                              content: Text(
                                'This will permanently delete "${items[i].name}". This action cannot be undone.',
                                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text('Cancel', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          masterCubit.delete(items[i].id).then((err) {
                            if (err != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err), backgroundColor: AppColors.ink),
                              );
                            }
                          });
                        },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.silver.withValues(alpha: 0.18) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.silver : Theme.of(context).dividerColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
              color: selected ? AppColors.silver : cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? AppColors.silver.withValues(alpha: 0.25) : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: TextStyle(
                color: selected ? AppColors.silver : cs.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Master item detail sheet ────────────────────────────────────────────────

void _showMasterDetail(BuildContext context, MasterItem item, IconData icon, Color color) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      behavior: HitTestBehavior.opaque,
      child: _MasterDetailSheet(item: item, icon: icon, color: color),
    ),
  );
}

class _MasterDetailSheet extends StatelessWidget {
  final MasterItem item;
  final IconData icon;
  final Color color;
  const _MasterDetailSheet({required this.item, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = <MapEntry<String, String>>[
      if (item.fullForm != null && item.fullForm!.isNotEmpty) MapEntry('Full Form', item.fullForm!),
      if (item.assignedCategoryName != null) MapEntry('Category', item.assignedCategoryName!),
      if (item.description != null && item.description!.isNotEmpty) MapEntry('Description', item.description!),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => GestureDetector(
        onTap: () {}, // absorb taps so the outer dismiss handler ignores sheet touches
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.name, style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Expanded(
                child: details.isEmpty
                    ? Center(child: Text('No additional details', style: TextStyle(color: cs.onSurfaceVariant)))
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: details.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key.toUpperCase(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                              const SizedBox(height: 4),
                              Text(e.value, style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.4)),
                            ],
                          ),
                        )).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  final MasterItem item;
  final IconData icon;
  final Color color;
  final VoidCallback onView, onEdit, onDelete;
  const _MasterCard({required this.item, required this.icon, required this.color, required this.onView, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(AppColors.surface, color, 0.32)!;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    final statusColor = item.isActive ? AppColors.positive : AppColors.ink.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwipeActions(
        onTap: onView,
        actions: [
          SwipeAction(icon: Icons.edit_outlined, label: 'Edit', color: AppColors.brand, onTap: onEdit),
          SwipeAction(icon: Icons.delete_outline, label: 'Delete', color: AppColors.error, onTap: onDelete),
        ],
        child: RichCardShell(
          accentColor: color,
          backgroundColor: bg,
          showAccentBar: false,
          edgeColor: color,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.75)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(icon, size: 20, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(item.name,
                              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      ]),
                      if (item.fullForm != null && item.fullForm!.isNotEmpty)
                        Text(item.fullForm!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (item.assignedCategoryName != null)
                        Row(children: [
                          Icon(Icons.category_rounded, size: 11, color: color),
                          const SizedBox(width: 3),
                          Text(item.assignedCategoryName!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      if (item.description != null)
                        Text(item.description!, style: TextStyle(color: fgMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: fgMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Generic Master Create / Edit Form ─────────────────────────────────────────

class _MasterFormBody extends StatefulWidget {
  final String typeKey;
  final String? editId;
  final String? defaultCategoryId; // pre-fill category when creating from drill-down
  final VoidCallback onSaved;
  const _MasterFormBody({required this.typeKey, this.editId, this.defaultCategoryId, required this.onSaved});
  @override
  State<_MasterFormBody> createState() => _MasterFormBodyState();
}

class _MasterFormBodyState extends State<_MasterFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fullFormCtrl = TextEditingController(); // Unit type only
  bool _isActive = true;
  bool _saving = false;
  bool _loadingItem = false;
  String? _loadError;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool get _isEdit => widget.editId != null;
  bool get _needsCategory => masterTypeFor(widget.typeKey)?.hasParentAssignment ?? false;
  bool get _isRemote => masterCubit.remoteDatasourceFor(widget.typeKey) != null;
  bool get _isUnit => widget.typeKey == 'unit';

  @override
  void initState() {
    super.initState();
    masterCubit.itemsOfType('companyCategory');
    if (_isEdit) {
      if (_isRemote) {
        _loadItemFromApi();
      } else {
        final state = masterCubit.state;
        if (state is MasterLoaded) {
          try {
            _fillFrom(state.items.firstWhere((c) => c.id == widget.editId));
          } catch (_) {}
        }
      }
    } else if (widget.defaultCategoryId != null) {
      // Pre-fill category when navigating from drill-down
      _selectedCategoryId = widget.defaultCategoryId;
      final cats = masterCubit.itemsOfType('companyCategory');
      try {
        _selectedCategoryName = cats.firstWhere((c) => c.id == widget.defaultCategoryId).name;
      } catch (_) {}
    }
  }

  void _fillFrom(MasterItem item) {
    _nameCtrl.text = item.name;
    _descCtrl.text = item.description ?? '';
    _fullFormCtrl.text = item.fullForm ?? '';
    _isActive = item.isActive;
    _selectedCategoryId = item.assignedCategoryId;
    _selectedCategoryName = item.assignedCategoryName;
  }

  Future<void> _loadItemFromApi() async {
    setState(() => _loadingItem = true);
    try {
      final item = await masterCubit.remoteDatasourceFor(widget.typeKey)!.getById(widget.editId!);
      if (!mounted) return;
      setState(() => _fillFrom(item));
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingItem = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _fullFormCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsCategory && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company category')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final state = masterCubit.state as MasterLoaded;
        final existing = state.items.firstWhere((c) => c.id == widget.editId!);
        await masterCubit.update(existing.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          assignedCategoryId: _selectedCategoryId,
          assignedCategoryName: _selectedCategoryName,
          fullForm: _isUnit && _fullFormCtrl.text.trim().isNotEmpty ? _fullFormCtrl.text.trim() : null,
        ));
      } else {
        await masterCubit.add(MasterItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          typeKey: widget.typeKey,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          isActive: _isActive,
          createdAt: DateTime.now(),
          fullForm: _isUnit && _fullFormCtrl.text.trim().isNotEmpty ? _fullFormCtrl.text.trim() : null,
          assignedCategoryId: _selectedCategoryId,
          assignedCategoryName: _selectedCategoryName,
        ));
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeCfg = masterTypeFor(widget.typeKey);
    final categories = masterCubit.itemsOfType('companyCategory');

    if (_loadingItem) {
      return const Center(child: CircularProgressIndicator(color: AppColors.silver));
    }
    if (_loadError != null) {
      return Center(child: Text(_loadError!, style: TextStyle(color: cs.onSurfaceVariant)));
    }

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                if (_isUnit) ...[
                  BrixenTextField(
                    label: 'Unit *',
                    hint: 'e.g. pcs',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.straighten_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),
                  BrixenTextField(
                    label: 'Full Form',
                    hint: 'e.g. Pieces',
                    controller: _fullFormCtrl,
                    prefixIcon: const Icon(Icons.text_fields_rounded),
                  ),
                  const SizedBox(height: 18),
                  BrixenTextField(
                    label: 'Description',
                    hint: 'e.g. Number of garments',
                    controller: _descCtrl,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    maxLines: 3,
                  ),
                ] else ...[
                  BrixenTextField(
                    label: '${typeCfg?.name ?? 'Item'} Name *',
                    hint: 'Enter name',
                    controller: _nameCtrl,
                    prefixIcon: Icon(typeCfg?.icon ?? Icons.list_alt_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 18),
                  if (_needsCategory) ...[
                    _CategoryDropdown(
                      categories: categories,
                      selectedId: _selectedCategoryId,
                      onChanged: (id, name) => setState(() {
                        _selectedCategoryId = id;
                        _selectedCategoryName = name;
                      }),
                    ),
                    const SizedBox(height: 18),
                  ],
                  BrixenTextField(
                    label: 'Description',
                    hint: 'Optional description',
                    controller: _descCtrl,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BrixenButton(
            label: _isEdit ? 'Save Changes' : 'Create ${typeCfg?.name ?? 'Item'}',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ),
      ],
    );
  }
}


// ── Company Category Dropdown ─────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final List<MasterItem> categories;
  final String? selectedId;
  final void Function(String id, String name) onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId != null
        ? categories.where((c) => c.id == selectedId).firstOrNull
        : null;

    return BrixenDropdown<MasterItem>(
      hint: 'Assign to Company Category *',
      value: selected,
      items: categories,
      labelOf: (c) => c.name,
      icon: Icons.category_outlined,
      onChanged: (item) {
        if (item == null) return;
        onChanged(item.id, item.name);
      },
    );
  }
}

// ── Multiline field with top-left icon ────────────────────────────────────────

// ── Master Menu Category View ─────────────────────────────────────────────────

class _MasterMenuCategoryView extends StatefulWidget {
  final void Function(String catId) onCategoryTap;
  const _MasterMenuCategoryView({required this.onCategoryTap});

  @override
  State<_MasterMenuCategoryView> createState() => _MasterMenuCategoryViewState();
}

class _MasterMenuCategoryViewState extends State<_MasterMenuCategoryView> {
  @override
  void initState() {
    super.initState();
    masterCubit.load('masterMenu');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<MasterCubit, MasterState>(
      bloc: masterCubit,
      builder: (_, state) {
        if (state is! MasterLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.silver));
        }

        // Group items by category
        final grouped = <String, List<MasterItem>>{};
        for (final item in state.items) {
          final key = item.assignedCategoryId ?? '__none';
          grouped.putIfAbsent(key, () => []).add(item);
        }

        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_to_queue_outlined, size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No master menus yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Tap + to create one', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
          children: [
            Text('${grouped.length} ${grouped.length == 1 ? 'category' : 'categories'} · ${state.items.length} total menus',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 10),
            ...grouped.entries.map((e) {
              final catId = e.key;
              final items = e.value;
              final catName = items.first.assignedCategoryName ?? 'Unassigned';
              final activeCount = items.where((x) => x.isActive).length;
              final inactiveCount = items.length - activeCount;
              return _CategorySummaryCard(
                catId: catId,
                catName: catName,
                totalCount: items.length,
                activeCount: activeCount,
                inactiveCount: inactiveCount,
                onTap: () => widget.onCategoryTap(catId),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final String catId, catName;
  final int totalCount, activeCount, inactiveCount;
  final VoidCallback onTap;

  const _CategorySummaryCard({
    required this.catId, required this.catName, required this.totalCount,
    required this.activeCount, required this.inactiveCount, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.silver.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.silver.withValues(alpha: 0.3)),
              ),
              child: const Center(child: Icon(Icons.category_outlined, size: 20, color: AppColors.silver)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catName, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _CountBadge(count: activeCount, label: 'Active', color: AppColors.accentEmerald),
                      const SizedBox(width: 8),
                      if (inactiveCount > 0)
                        _CountBadge(count: inactiveCount, label: 'Inactive', color: AppColors.accentRose),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$totalCount', style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('menus', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _CountBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text('$count $label', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

String _inr(int v) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(v);

const _planPrices = <String, int>{
  'Basic': 10000,
  'Professional': 25000,
  'Enterprise': 130000,
};

const _planAccents = <String, Color>{
  'Basic':        AppColors.accentSlate,
  'Standard':     AppColors.accentTeal,
  'Professional': AppColors.accentIndigo,
  'Enterprise':   AppColors.accentViolet,
};

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  static String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _dateStr() {
    final n = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${n.day} ${m[n.month - 1]} ${n.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);
    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.silver)),
      error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      data: (all) {
        final active = all.where((c) => c.isActive).length;

        // Subscription breakdown
        final planCount = <String, int>{};
        for (final c in all) {
          if (c.subscriptionPlan != null) {
            planCount[c.subscriptionPlan!] = (planCount[c.subscriptionPlan!] ?? 0) + 1;
          }
        }
        final planRev = <String, int>{};
        var totalRev = 0;
        for (final e in planCount.entries) {
          final r = e.value * (_planPrices[e.key] ?? 0);
          planRev[e.key] = r;
          totalRev += r;
        }

        final recent = ([...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(4).toList();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;

        // Month-over-month new-company growth (only shown when computable).
        final now = DateTime.now();
        final thisMonth = all.where((c) => c.createdAt.year == now.year && c.createdAt.month == now.month).length;
        final lastMonthDate = DateTime(now.year, now.month - 1);
        final lastMonth = all.where((c) => c.createdAt.year == lastMonthDate.year && c.createdAt.month == lastMonthDate.month).length;
        final growthPct = lastMonth > 0 ? (((thisMonth - lastMonth) / lastMonth) * 100).round() : null;

        // 11 weekly buckets (oldest → newest) of how many companies signed up —
        // drives the hero card's dot-column chart bar heights (1–3 dots each).
        final weekly = List.generate(11, (i) {
          final weeksAgo = 10 - i;
          final start = now.subtract(Duration(days: (weeksAgo + 1) * 7));
          final end = now.subtract(Duration(days: weeksAgo * 7));
          return all.where((c) => c.createdAt.isAfter(start) && c.createdAt.isBefore(end)).length;
        });

        final activePct = all.isNotEmpty ? (active / all.length * 100).round() : 0;
        final inactivePct = all.isNotEmpty ? 100 - activePct : 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greet(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Admin', style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(_dateStr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Hero stat card ───────────────────────────────────────
            _HeroStatCard(total: all.length, weekly: weekly, growthPct: growthPct),
            const SizedBox(height: 14),

            // ── Active / Inactive split card ──────────────────────────
            _SplitStatCard(activePct: activePct, inactivePct: inactivePct),
            const SizedBox(height: 16),

            // ── Revenue Overview ─────────────────────────────────────
            _DashSectionLabel('Revenue Overview'),
            const SizedBox(height: 6),
            _RevenueCard(totalRev: totalRev, planRev: planRev, isDark: isDark),
            const SizedBox(height: 16),

            // ── Subscription by Plan ─────────────────────────────────
            _DashSectionLabel('Subscriptions by Plan'),
            const SizedBox(height: 6),
            _PlanBreakdown(planCount: planCount, planRev: planRev, total: all.length, isDark: isDark),
            const SizedBox(height: 16),

            // ── Recent Companies ─────────────────────────────────────
            _DashSectionLabel('Recent Companies'),
            const SizedBox(height: 6),
            ...recent.map((c) => _RecentRow(company: c, isDark: isDark)),
          ],
        );
      },
    );
  }
}

class _DashSectionLabel extends StatelessWidget {
  final String label;
  const _DashSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: isDark ? AppColors.silver : AppColors.lightPrimary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final int total;
  final List<int> weekly; // new-signup count per weekly bucket, oldest → newest
  final int? growthPct; // null when not computable (no data for previous month)

  const _HeroStatCard({
    required this.total,
    required this.weekly,
    required this.growthPct,
  });

  @override
  Widget build(BuildContext context) {
    final up = (growthPct ?? 0) >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                total.toString(),
                style: const TextStyle(color: AppColors.ink, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1),
              ),
              if (growthPct != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: up ? AppColors.positive : AppColors.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${growthPct!.abs()}%', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      child: Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 11, color: up ? AppColors.positive : AppColors.ink),
                    ),
                  ]),
                ),
              ],
              const Spacer(),
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                child: const Center(
                  child: Text('B', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Total companies · vs previous 3 months', style: TextStyle(color: AppColors.textHint, fontSize: 12.5)),
          if (weekly.isNotEmpty) ...[
            const SizedBox(height: 22),
            _DotColumnChart(weekly: weekly),
          ],
        ],
      ),
    );
  }
}

class _DotColumnChart extends StatelessWidget {
  final List<int> weekly;
  const _DotColumnChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    const rows = 3;
    const dot = 10.0;
    const gap = 6.0;

    return SizedBox(
      height: rows * dot + (rows - 1) * gap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(weekly.length, (i) {
          final height = weekly[i].clamp(0, rows) == 0 ? 1 : weekly[i].clamp(1, rows);
          final light = height <= 1 || (i.isEven && height < rows);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(height, (r) {
              return Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                child: Container(
                  width: dot, height: dot,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: light ? AppColors.brandLight : AppColors.brand),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _SplitStatCard extends StatelessWidget {
  final int activePct;
  final int inactivePct;

  const _SplitStatCard({required this.activePct, required this.inactivePct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brand, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _SplitHalf(filled: true, icon: Icons.groups_rounded, pct: activePct, label: 'Active')),
            const SizedBox(width: 8),
            Expanded(child: _SplitHalf(filled: false, icon: Icons.person_off_rounded, pct: inactivePct, label: 'Inactive')),
          ],
        ),
      ),
    );
  }
}

class _SplitHalf extends StatelessWidget {
  final bool filled; // left/blue-filled half vs right/white half
  final IconData icon;
  final int pct;
  final String label;

  const _SplitHalf({required this.filled, required this.icon, required this.pct, required this.label});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : AppColors.ink;
    final iconBg = filled ? Colors.white.withValues(alpha: 0.16) : AppColors.brand.withValues(alpha: 0.1);
    final iconFg = filled ? AppColors.white : AppColors.brand;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: filled ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: iconFg),
          ),
          const SizedBox(height: 14),
          Text('$pct%', style: TextStyle(color: fg, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int totalRev;
  final Map<String, int> planRev;
  final bool isDark;

  const _RevenueCard({required this.totalRev, required this.planRev, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.silver.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Received', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _inr(totalRev),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.silver.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.silver, size: 22),
              ),
            ],
          ),

          if (totalRev > 0) ...[
            const SizedBox(height: 18),
            // Segmented bar
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: planRev.entries.map((e) {
                    return Flexible(
                      flex: ((e.value / totalRev) * 1000).round(),
                      child: Container(color: _planAccents[e.key] ?? AppColors.silver),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Legend
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: planRev.entries.map((e) {
                final color = _planAccents[e.key] ?? AppColors.silver;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key}  ${_inr(e.value)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanBreakdown extends StatelessWidget {
  final Map<String, int> planCount;
  final Map<String, int> planRev;
  final int total;
  final bool isDark;

  const _PlanBreakdown({
    required this.planCount,
    required this.planRev,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (planCount.isEmpty) {
      return Center(child: Text('No subscriptions yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }

    final entries = planCount.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: entries.asMap().entries.map((entry) {
          final i = entry.key;
          final plan = entry.value.key;
          final count = entry.value.value;
          final rev = planRev[plan] ?? 0;
          final color = _planAccents[plan] ?? AppColors.silver;
          final pct = total > 0 ? (count / total * 100).round() : 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 40,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
                                child: Text('$count ${count == 1 ? 'co.' : 'cos.'}',
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 7),
                              Text('$pct% of total', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _inr(rev),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
              ),
              if (i < entries.length - 1)
                Divider(height: 1, color: Theme.of(context).dividerColor, indent: 33),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final Company company;
  final bool isDark;

  const _RecentRow({required this.company, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plan = company.subscriptionPlan;
    final planColor = plan != null ? (_planAccents[plan] ?? AppColors.silver) : AppColors.silverDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: planColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: planColor.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(company.initials, style: TextStyle(color: planColor, fontWeight: FontWeight.w800, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company.name, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                if (plan != null)
                  Text(plan, style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: company.isActive
                  ? AppColors.accentEmerald.withValues(alpha: 0.12)
                  : AppColors.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: company.isActive
                    ? AppColors.accentEmerald.withValues(alpha: 0.4)
                    : AppColors.accentRose.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              company.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: company.isActive ? AppColors.accentEmerald : AppColors.accentRose,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

