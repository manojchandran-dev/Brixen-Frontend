import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_logo.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../domain/entities/company.dart';
import '../providers/companies_provider.dart';
import '../widgets/company_card.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/domain/entities/master_type.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../../masters/presentation/cubit/master_state.dart';
import '../../../attendance/presentation/pages/attendance_body.dart';
import '../../../reports/presentation/pages/reports_body.dart';

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CompaniesView();
  }
}

class _CompaniesView extends ConsumerStatefulWidget {
  const _CompaniesView();

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
            leading: _inMenuSub
                ? GestureDetector(
                    onTap: _pop,
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
                  )
                : null,
            title: _inMenuSub ? _buildBreadcrumb(cs) : Row(
              children: [
                const BrixenLogo(size: 32, animate: false),
                const SizedBox(width: 10),
                Text(_navLabel(_navIndex), style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
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
    final crumbs = <_Crumb>[_Crumb('Menu', () => _popTo(0))];
    for (int i = 0; i < _stack.length; i++) {
      final seg = _stack[i];
      final depth = i + 1;
      final isLast = i == _stack.length - 1;
      final label = _segLabel(seg);
      crumbs.add(_Crumb(label, isLast ? null : () => _popTo(depth)));
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
        width: 36, height: 36,
        margin: const EdgeInsets.only(right: 12),
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
        child: Icon(Icons.add, size: 18, color: isDark ? AppColors.black : AppColors.white),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_navIndex == 3 && _stack.isNotEmpty) {
      final path = _stack.join('/');
      if (path == 'companies') return _CompaniesListBody(searchCtrl: _searchCtrl);
      if (path == 'masters') {
        return _MastersListBody(
          onTypeTap: (key) => _push(key),
          onCreateTap: (key) { _push(key); _push('create'); },
        );
      }

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
      case 0: return const _DashboardBody();
      case 1: return const AttendanceBody();
      case 2: return const ReportsBody();
      case 3: return _MenuBody(
        onCompaniesTap: () => _push('companies'),
        onEmployeesTap: () => context.push(AppRouter.employees),
        onMastersTap: () => _push('masters'),
      );
      default: return const SizedBox.shrink();
    }
  }

  String _navLabel(int i) => ['Dashboard', 'Attendance', 'Reports', 'Menu'][i];
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onChanged: (v) => ref.read(companiesProvider.notifier).search(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Companies', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text(companies.length.toString().padLeft(2, '0'),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
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
                          onToggleStatus: () => ref.read(companiesProvider.notifier).toggleStatus(c.id),
                          onDelete: () => ref.read(companiesProvider.notifier).deleteCompany(c.id),
                          onView: () => _showCompanyDetail(context, c),
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

void _showCompanyDetail(BuildContext context, dynamic company) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CompanyDetailSheet(company: company),
  );
}

class _CompanyDetailSheet extends StatelessWidget {
  final dynamic company;
  const _CompanyDetailSheet({required this.company});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = company;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Center(child: Text(c.initials, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 15))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                        if (c.industryType != null)
                          Text(c.industryType!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isActive ? AppColors.accentEmerald.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.isActive ? AppColors.accentEmerald.withValues(alpha: 0.4) : Theme.of(context).dividerColor),
                    ),
                    child: Text(c.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: c.isActive ? AppColors.accentEmerald : cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            // Details list
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _DetailSection(title: 'Contact Information', items: [
                    _DetailRow(icon: Icons.person_outline,     label: 'Owner',  value: c.ownerName),
                    _DetailRow(icon: Icons.mail_outline_rounded, label: 'Email', value: c.email),
                    if (c.phone != null)    _DetailRow(icon: Icons.phone_outlined,     label: 'Phone',   value: c.phone!),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection(title: 'Location', items: [
                    if (c.address != null)  _DetailRow(icon: Icons.location_on_outlined,   label: 'Address', value: c.address!),
                    if (c.city != null)     _DetailRow(icon: Icons.location_city_outlined, label: 'City',    value: c.city!),
                    if (c.state != null)    _DetailRow(icon: Icons.map_outlined,           label: 'State',   value: c.state!),
                    if (c.country != null)  _DetailRow(icon: Icons.language_outlined,      label: 'Country', value: c.country!),
                    if (c.pincode != null)  _DetailRow(icon: Icons.pin_outlined,           label: 'Pincode', value: c.pincode!),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection(title: 'Business', items: [
                    if (c.industryType != null)     _DetailRow(icon: Icons.work_outline,             label: 'Industry',     value: c.industryType!),
                    if (c.subscriptionPlan != null) _DetailRow(icon: Icons.card_membership_outlined, label: 'Plan',         value: c.subscriptionPlan!),
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Created', value: '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}'),
                  ]),
                ],
              ),
            ),
          ],
        ),
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
        Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: items.asMap().entries.map((e) => Column(
              children: [
                e.value,
                if (e.key < items.length - 1) Divider(height: 1, color: Theme.of(context).dividerColor, indent: 48),
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
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}


// ── Menu full page ────────────────────────────────────────────────────────────

class _MenuBody extends StatelessWidget {
  final VoidCallback onCompaniesTap;
  final VoidCallback onEmployeesTap;
  final VoidCallback onMastersTap;
  const _MenuBody({required this.onCompaniesTap, required this.onEmployeesTap, required this.onMastersTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ── Premium profile card ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.silverGradient
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C1C1C), Color(0xFF0D0D0D)],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.silver.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Center(
                  child: Text('AD',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? AppColors.black : AppColors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin',
                        style: TextStyle(
                            color: isDark ? AppColors.black : AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Super Admin',
                          style: TextStyle(
                              color: (isDark ? AppColors.black : AppColors.white)
                                  .withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: (isDark ? AppColors.black : AppColors.white).withValues(alpha: 0.6),
                  size: 20),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Navigation ────────────────────────────────────────────
        _MenuSectionLabel('Navigation'),
        const SizedBox(height: 8),
        _MenuSection(items: [
          _MenuItem(icon: Icons.business_rounded,         label: 'Companies',    color: AppColors.accentIndigo,  onTap: onCompaniesTap),
          _MenuItem(icon: Icons.badge_rounded,            label: 'Employees',    color: AppColors.accentTeal,    onTap: onEmployeesTap),
          _MenuItem(icon: Icons.receipt_long_rounded,     label: 'Sales',        color: AppColors.accentViolet,  onTap: () => context.push(AppRouter.sales)),
          _MenuItem(icon: Icons.people_alt_rounded,       label: 'Customers',    color: AppColors.accentGold,    onTap: () => context.push(AppRouter.customers)),
          _MenuItem(icon: Icons.receipt_outlined,         label: 'Expense',      color: AppColors.accentRose,    onTap: () => context.push(AppRouter.expenses)),
          _MenuItem(icon: Icons.people_rounded,           label: 'Users',        color: AppColors.accentViolet,  onTap: () {}),
          _MenuItem(icon: Icons.card_membership_rounded,  label: 'Subscriptions',color: AppColors.accentGold,    onTap: () {}),
          _MenuItem(icon: Icons.track_changes_rounded,    label: 'Activity Log', color: AppColors.accentSlate,   onTap: () {}),
        ]),
        const SizedBox(height: 16),

        // ── Masters ───────────────────────────────────────────────
        _MenuSectionLabel('Masters'),
        const SizedBox(height: 8),
        _MenuSection(items: [
          _MenuItem(icon: Icons.list_alt_rounded, label: 'Masters', color: AppColors.silverDark, onTap: onMastersTap),
        ]),
        const SizedBox(height: 16),

        // ── Preferences ───────────────────────────────────────────
        _MenuSectionLabel('Preferences'),
        const SizedBox(height: 8),
        _MenuSection(items: [
          _MenuItem(icon: Icons.settings_rounded, label: 'Settings', color: AppColors.accentSlate,  onTap: () {}),
          _MenuItem(icon: Icons.help_rounded,     label: 'Support',  color: AppColors.accentTeal,   onTap: () {}),
        ]),
        const SizedBox(height: 16),

        // ── Theme toggle ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            bloc: themeCubit,
            builder: (context, mode) {
              final dark = mode == ThemeMode.dark;
              return Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(dark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                        size: 18, color: AppColors.accentGold),
                  ),
                  const SizedBox(width: 14),
                  Text(dark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => themeCubit.toggle(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46, height: 26,
                      decoration: BoxDecoration(
                        color: dark ? AppColors.silver.withValues(alpha: 0.25) : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.silver.withValues(alpha: 0.4)),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 20, height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(color: AppColors.silver, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── Logout ────────────────────────────────────────────────
        GestureDetector(
          onTap: () => context.go(AppRouter.signIn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                ),
                const SizedBox(width: 14),
                const Text('Logout',
                    style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.error.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
        ),
      ],
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
        Container(width: 3, height: 13, decoration: BoxDecoration(color: AppColors.silver, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: 13),
                      Text(item.label,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 17,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: Theme.of(context).dividerColor, indent: 61),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                _NavBtn(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', isActive: currentIndex == 0, onTap: () => onTap(0)),
                _NavBtn(icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled_rounded, label: 'Attendance', isActive: currentIndex == 1, onTap: () => onTap(1)),
                _NavBtn(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Report', isActive: currentIndex == 2, onTap: () => onTap(2)),
                _NavBtn(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Menu', isActive: currentIndex == 3, onTap: () => onTap(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.activeIcon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.textSecondary : AppColors.lightTextHint;

    // Active: silver-gradient pill (dark) / near-black pill (light)
    final activePillColor = isDark ? null : const Color(0xFF111111);
    final activeContentColor = isDark ? AppColors.black : AppColors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: (isActive && isDark) ? AppColors.silverGradient : null,
            color: isActive ? activePillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark
                          ? AppColors.silver.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? activeContentColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeContentColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ── Masters List ─────────────────────────────────────────────────────────────

class _MastersListBody extends StatelessWidget {
  final void Function(String key) onTypeTap;
  final void Function(String key) onCreateTap;
  const _MastersListBody({required this.onTypeTap, required this.onCreateTap});

  static const _typeColors = {
    'companyCategory': AppColors.accentIndigo,
    'masterMenu':      AppColors.accentTeal,
    'expenseCategory': AppColors.accentRose,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        ...kMasterTypes.map((t) {
          final color = _typeColors[t.key] ?? AppColors.silver;
          return _MasterHubTile(
            label: t.name,
            icon: t.icon,
            color: color,
            isDark: isDark,
            onTap: () => onTypeTap(t.key),
            onCreateTap: () => onCreateTap(t.key),
          );
        }),
      ],
    );
  }
}

// ── Masters Hub Tile ──────────────────────────────────────────────────────────

class _MasterHubTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onCreateTap;

  const _MasterHubTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(
            children: [
              Container(width: 3, color: color),
              Container(
                width: 52,
                height: 60,
                color: color.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Tap to view all',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onCreateTap,
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: color),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search ${typeCfg?.name ?? 'items'}...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
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
                      itemBuilder: (_, i) => _MasterCard(
                        item: items[i],
                        icon: typeCfg?.icon ?? Icons.list_alt_outlined,
                        onEdit: () => widget.onEdit(items[i].id),
                        onToggle: () => masterCubit.toggleStatus(items[i].id),
                        onDelete: () => masterCubit.delete(items[i].id),
                      ),
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

class _MasterCard extends StatelessWidget {
  final MasterItem item;
  final IconData icon;
  final VoidCallback onEdit, onToggle, onDelete;
  const _MasterCard({required this.item, required this.icon, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, size: 18, color: AppColors.silver)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                if (item.assignedCategoryName != null)
                  Row(children: [
                    Icon(Icons.category_outlined, size: 11, color: AppColors.silver),
                    const SizedBox(width: 3),
                    Text(item.assignedCategoryName!, style: TextStyle(color: AppColors.silver, fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                if (item.description != null)
                  Text(item.description!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isActive ? AppColors.accentEmerald.withValues(alpha: 0.12) : AppColors.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.isActive ? AppColors.accentEmerald.withValues(alpha: 0.35) : AppColors.accentRose.withValues(alpha: 0.35)),
            ),
            child: Text(item.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: item.isActive ? AppColors.accentEmerald : AppColors.accentRose, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant, size: 20),
            color: cs.surfaceContainerHighest,
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'toggle') onToggle();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: cs.onSurface), const SizedBox(width: 10), Text('Edit', style: TextStyle(color: cs.onSurface, fontSize: 13))])),
              PopupMenuItem(value: 'toggle', child: Row(children: [Icon(item.isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16, color: cs.onSurface), const SizedBox(width: 10), Text(item.isActive ? 'Mark Inactive' : 'Mark Active', style: TextStyle(color: cs.onSurface, fontSize: 13))])),
              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.error), const SizedBox(width: 10), const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13))])),
            ],
          ),
        ],
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
  bool _isActive = true;
  bool _saving = false;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool get _isEdit => widget.editId != null;
  bool get _needsCategory => masterTypeFor(widget.typeKey)?.hasParentAssignment ?? false;

  @override
  void initState() {
    super.initState();
    masterCubit.itemsOfType('companyCategory');
    if (_isEdit) {
      final state = masterCubit.state;
      if (state is MasterLoaded) {
        try {
          final item = state.items.firstWhere((c) => c.id == widget.editId);
          _nameCtrl.text = item.name;
          _descCtrl.text = item.description ?? '';
          _isActive = item.isActive;
          _selectedCategoryId = item.assignedCategoryId;
          _selectedCategoryName = item.assignedCategoryName;
        } catch (_) {}
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_needsCategory && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company category')),
      );
      return;
    }
    setState(() => _saving = true);
    if (_isEdit) {
      final state = masterCubit.state as MasterLoaded;
      final existing = state.items.firstWhere((c) => c.id == widget.editId!);
      masterCubit.update(existing.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        isActive: _isActive,
        assignedCategoryId: _selectedCategoryId,
        assignedCategoryName: _selectedCategoryName,
      ));
    } else {
      masterCubit.add(MasterItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        typeKey: widget.typeKey,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        isActive: _isActive,
        createdAt: DateTime.now(),
        assignedCategoryId: _selectedCategoryId,
        assignedCategoryName: _selectedCategoryName,
      ));
    }
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeCfg = masterTypeFor(widget.typeKey);
    final categories = masterCubit.itemsOfType('companyCategory');

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: '${typeCfg?.name ?? 'Item'} Name *',
                    hintText: 'Enter name',
                    prefixIcon: Icon(typeCfg?.icon ?? Icons.list_alt_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                if (_needsCategory) ...[
                  _CategoryDropdown(
                    categories: categories,
                    selectedId: _selectedCategoryId,
                    onChanged: (id, name) => setState(() {
                      _selectedCategoryId = id;
                      _selectedCategoryName = name;
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
                _MultilineField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Optional description',
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 20),
                Text('Status', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(children: [
                  _MasterStatusBtn(label: 'Active',   selected: _isActive,  isActive: true,  onTap: () => setState(() => _isActive = true)),
                  const SizedBox(width: 12),
                  _MasterStatusBtn(label: 'Inactive', selected: !_isActive, isActive: false, onTap: () => setState(() => _isActive = false)),
                ]),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.silver : AppColors.lightTextPrimary,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.black : AppColors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Create ${typeCfg?.name ?? 'Item'}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            );
          }),
        ),
      ],
    );
  }
}

class _MasterStatusBtn extends StatelessWidget {
  final String label;
  final bool selected, isActive;
  final VoidCallback onTap;
  const _MasterStatusBtn({required this.label, required this.selected, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = AppColors.accentEmerald;
    const red   = AppColors.accentRose;

    final Color fillColor  = isActive ? green : red;
    final IconData icon    = selected
        ? (isActive ? Icons.check_circle_rounded : Icons.cancel_rounded)
        : (isActive ? Icons.check_circle_outline : Icons.cancel_outlined);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? fillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? fillColor : Theme.of(context).dividerColor,
              width: selected ? 0 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: fillColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15,
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
                letterSpacing: 0.2,
              )),
            ],
          ),
        ),
      ),
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

class _MultilineField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  const _MultilineField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLabel = _focused || _hasText;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.silver : Theme.of(context).dividerColor,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 14),
                child: Icon(widget.icon, color: cs.onSurfaceVariant, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: 3,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: showLabel ? widget.hint : widget.label,
                    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: showLabel ? 14 : 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel)
          Positioned(
            top: -9,
            left: 12,
            child: Container(
              color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: _focused ? AppColors.silver : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
        final inactive = all.length - active;

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

            // ── Stat cards ───────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatCard(value: all.length, label: 'Companies', icon: Icons.business_outlined, accent: AppColors.silver, isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(value: active, label: 'Active', icon: Icons.check_circle_outline, accent: AppColors.accentEmerald, isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(value: inactive, label: 'Inactive', icon: Icons.remove_circle_outline, accent: AppColors.accentRose, isDark: isDark)),
              ],
            ),
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
        color: isDark ? AppColors.silver : AppColors.lightTextPrimary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
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

