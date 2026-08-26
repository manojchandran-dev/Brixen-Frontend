import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/action_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employeesAsync = ref.watch(employeesProvider);

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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employees',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  employeesAsync.whenOrNull(
                        data: (list) => Text(
                          '${list.length} records',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
        actions: [
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
                  hintText: 'Search by name, code or department…',
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
          Expanded(
            child: employeesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
              ),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list
                          .where(
                            (e) =>
                                e.fullName.toLowerCase().contains(q) ||
                                e.employeeCode.toLowerCase().contains(q) ||
                                (e.department?.toLowerCase().contains(q) ??
                                    false),
                          )
                          .toList();

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
                          list.isEmpty ? 'No employees yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (list.isEmpty) ...[
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _EmployeeCard(employee: filtered[i], index: i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatSummaryCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.75)],
                ),
                shape: BoxShape.circle,
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]),
              ),
              child: Icon(icon, size: 16, color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    final fgFaint = AppColors.ink.withValues(alpha: 0.4);

    return SwipeActions(
      onTap: () => _showEmployeeDetail(context, ref, employee, accent),
      actions: [
        SwipeAction(
          icon: Icons.sync_alt_rounded,
          label: 'Status',
          color: AppColors.accentGold,
          onTap: () => _openStatusPicker(context, ref),
        ),
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () => context.push(AppRouter.createEmployee, extra: employee),
        ),
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
        edgeColor: accent,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  employee.fullName.trim().isNotEmpty
                      ? employee.fullName.trim()[0].toUpperCase()
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
                      employee.fullName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.designation ?? employee.department ?? '—',
                      style: TextStyle(fontSize: 12, color: fgMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.employeeCode,
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
                    .deleteEmployee(employee.id);
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
                color: AppColors.accentRose,
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
                    .updateEmployee(employee.copyWith(status: s));
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
      onEdit: () {
        Navigator.of(ctx).pop();
        ctx.push(AppRouter.createEmployee, extra: employee);
      },
      onDelete: () async {
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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
              .deleteEmployee(employee.id);
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
        onTap: () => _openEmployeeStatusPicker(ctx, ref, employee),
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
