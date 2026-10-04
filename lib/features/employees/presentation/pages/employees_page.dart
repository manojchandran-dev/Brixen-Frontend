import 'dart:async';
import '../../../../shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/deleted_items_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/action_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/super_admin_company_filter_bar.dart';
import 'package:intl/intl.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/employee.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/search_field.dart';
import '../providers/employees_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const EmployeesPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Filter sheet choices (null = All) and the search text — both go to the
  // API (see employeeResultsProvider).
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

  void _openFilter(List<Employee> all) {
    final server =
        ref
            .read(listFilterOptionsProvider(ApiEndpoints.employees))
            .valueOrNull ??
        const {};
    List<(Object, String)> opts(String key, List<(Object, String)> fallback) {
      final o = serverOptions(server, key);
      return o.isEmpty ? fallback : o;
    }

    showChipFilterSheet(
      context,
      title: 'Filter employees',
      sections: [
        FilterSection(
          key: 'status',
          title: 'Status',
          options: opts('status', distinctOptions(all, (e) => e.status)),
        ),
        FilterSection(
          key: 'department',
          title: 'Department',
          options: opts(
            'department',
            distinctOptions(all, (e) => e.department),
          ),
        ),
        FilterSection(
          key: 'employment_type',
          title: 'Employment type',
          options: opts(
            'employment_type',
            distinctOptions(all, (e) => e.employmentType),
          ),
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
    final employeesAsync = query.isEmpty
        ? ref.watch(employeesProvider)
        : ref.watch(employeeResultsProvider(query));
    // Loads the filter choices ahead of the sheet opening.
    ref.watch(listFilterOptionsProvider(ApiEndpoints.employees));

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
                      'Employees',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ModuleTitle(title: 'Employees', subtitle: 'Manage your staff'),
        actions: [
          if (ref.watch(moduleAccessProvider('Employees')).create)
            GestureDetector(
              onTap: () => context.push(
                AppRouter.createEmployee,
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
            onFilter: () => _openFilter(employeesAsync.valueOrNull ?? const []),
            actions: [
              if (ref.watch(moduleAccessProvider('Employees')).delete)
                DeletedItemsButton(
                  title: 'Deleted employees',
                  listPath: ApiEndpoints.employees,
                  restorePath: (e) =>
                      '${ApiEndpoints.employees}/${e['id']}/restore',
                  labelOf: (e) =>
                      '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim(),
                  subtitleOf: (e) => e['employee_code'] as String?,
                  onRestored: () => ref.invalidate(employeesProvider),
                  inline: true,
                ),
            ],
          ),
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: employeesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(employeesProvider),
              ),
              data: (all) {
                final filtered = all;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? 'No employees yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add your first employee',
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

                return Column(
                  children: [
                    ListCountBar(
                      label: 'Total Employees',
                      count: filtered.length,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _EmployeeCard(employee: filtered[i], index: i),
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

/// Label + colour for an employee status ("On Leave", "on_leave"…).
(String, Color) _statusLook(String status) {
  final k = status.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  return switch (k) {
    'active' => ('Active', AppColors.positive),
    'onleave' => ('On leave', AppColors.brandLight),
    _ => (
      status.isEmpty
          ? 'Unknown'
          : status[0].toUpperCase() + status.substring(1),
      AppColors.textSecondary,
    ),
  };
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// Small tinted chip with an icon (employee code, employment type).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({required this.icon, required this.text, required this.color});

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
          Icon(icon, size: 11, color: AppColors.ink.withValues(alpha: 0.6)),
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

/// Status on the right of the card: green Active, grey Inactive, On leave.
class _EmployeeStatusPill extends StatelessWidget {
  final String status;
  const _EmployeeStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusLook(status);
    final active = color == AppColors.positive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(colors: AppColors.accentGradient(color))
            : null,
        color: active ? null : AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: active
            ? null
            : Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final Employee employee;
  final int index;
  const _EmployeeCard({required this.employee, this.index = 0});

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
    final bg = Color.lerp(
      AppColors.surface,
      accent,
      AppColors.cardTintBlend(accent),
    )!;

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.55);

    return SwipeActions(
      onTap: () => _showEmployeeDetail(context, ref, employee, accent),
      actions: [
        if (ref.watch(moduleAccessProvider('Employees')).edit)
          SwipeAction(
            icon: Icons.sync_alt_rounded,
            label: 'Status',
            color: AppColors.accentGold,
            onTap: () => _openStatusPicker(context, ref),
          ),
        if (ref.watch(moduleAccessProvider('Employees')).edit)
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () =>
                context.push(AppRouter.createEmployee, extra: employee),
          ),
        if (ref.watch(moduleAccessProvider('Employees')).delete)
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
        // Compact: avatar (status dot) · name / role · department / code &
        // type chips · status pill.
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                      employee.fullName.trim().isNotEmpty
                          ? employee.fullName.trim()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: _statusLook(employee.status).$2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [employee.designation, employee.department]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(' · ')
                          .ifEmpty('—'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: fgMuted),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.badge_outlined,
                          text: employee.employeeCode,
                          color: accent,
                        ),
                        if (employee.employmentType?.isNotEmpty == true)
                          _Chip(
                            icon: Icons.work_outline_rounded,
                            text: employee.employmentType!,
                            color: accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _EmployeeStatusPill(status: employee.status),
            ],
          ),
        ),
      ),
    );
  }

  void _openStatusPicker(BuildContext context, WidgetRef ref) {
    _openEmployeeStatusPicker(context, ref, employee);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Employee',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete "${employee.fullName}"? This cannot be undone.',
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
                    .read(employeesProvider.notifier)
                    .deleteEmployee(
                      employee.id,
                      companyId: Session.isSuperAdmin
                          ? employee.companyId
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

Color _employeeStatusColor(String status) {
  switch (status) {
    case 'Active':
      return AppColors.accentEmerald;
    case 'Inactive':
      return AppColors.accentRose;
    default:
      return AppColors.accentGold;
  }
}

const _employeeStatuses = ['Active', 'Inactive', 'On Leave'];

void _openEmployeeStatusPicker(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) {
  showActionSheet(
    context,
    title: 'Change Status',
    subtitle: employee.fullName,
    items: _employeeStatuses
        .map(
          (s) => ActionSheetItem(
            icon: Icons.circle,
            label: s,
            color: _employeeStatusColor(s),
            selected: s == employee.status,
            onTap: () async {
              if (s == employee.status) return;
              try {
                await ref
                    .read(employeesProvider.notifier)
                    .updateEmployee(
                      employee.copyWith(status: s),
                      companyId: Session.isSuperAdmin
                          ? employee.companyId
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
          ),
        )
        .toList(),
  );
}

void _showEmployeeDetail(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
  Color accent,
) {
  final statusColor = _employeeStatusColor(employee.status);
  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      avatarText: employee.fullName.trim().isNotEmpty
          ? employee.fullName.trim()[0].toUpperCase()
          : '?',
      avatarGradient: AppColors.accentGradient(accent),
      title: employee.fullName,
      subtitle: employee.designation ?? employee.department,
      onEdit: !ref.read(moduleAccessProvider('Employees')).edit
          ? null
          : () {
              Navigator.of(ctx).pop();
              ctx.push(AppRouter.createEmployee, extra: employee);
            },
      onDelete: !ref.read(moduleAccessProvider('Employees')).delete
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
                    'Delete Employee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  content: Text(
                    'Delete "${employee.fullName}"? This cannot be undone.',
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
                    .read(employeesProvider.notifier)
                    .deleteEmployee(
                      employee.id,
                      companyId: Session.isSuperAdmin
                          ? employee.companyId
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
      statusRow: GestureDetector(
        onTap: !ref.read(moduleAccessProvider('Employees')).edit
            ? null
            : () => _openEmployeeStatusPicker(ctx, ref, employee),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_rounded, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                employee.status,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'Tap to change',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.sync_alt_rounded,
                color: AppColors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
      sections: [
        DetailSection(
          title: 'Employment',
          items: [
            DetailRow(
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: employee.employeeCode,
            ),
            if (employee.department != null)
              DetailRow(
                icon: Icons.apartment_rounded,
                label: 'Department',
                value: employee.department!,
                iconColor: AppColors.positive,
              ),
            if (employee.employmentType != null)
              DetailRow(
                icon: Icons.work_outline_rounded,
                label: 'Employment Type',
                value: employee.employmentType!,
              ),
            if (employee.joiningDate != null)
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Joined',
                value: DateFormat('dd MMM yyyy').format(employee.joiningDate!),
                iconColor: AppColors.positive,
              ),
          ],
        ),
        DetailSection(
          title: 'Contact',
          items: [
            if (employee.phone != null)
              DetailRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: employee.phone!,
              ),
            if (employee.email != null)
              DetailRow(
                icon: Icons.mail_rounded,
                label: 'Email',
                value: employee.email!,
                iconColor: AppColors.positive,
              ),
            if (employee.address != null && employee.address!.isNotEmpty)
              DetailRow(
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: employee.address!,
              ),
          ],
        ),
      ],
    ),
  );
}
