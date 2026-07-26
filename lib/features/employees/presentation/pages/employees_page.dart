import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
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
                    Text('Employees', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employees', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
                  employeesAsync.whenOrNull(
                    data: (list) => Text('${list.length} records',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                  ) ?? const SizedBox.shrink(),
                ],
              ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createEmployee, extra: widget.fromMasters ? 'masters' : null),
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
                hintText: 'Search by name, code or department…',
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
            child: employeesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text(e.toString(), style: TextStyle(color: cs.error, fontSize: 13))),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list.where((e) =>
                        e.fullName.toLowerCase().contains(q) ||
                        e.employeeCode.toLowerCase().contains(q) ||
                        (e.department?.toLowerCase().contains(q) ?? false)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_outlined, size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          list.isEmpty ? 'No employees yet' : 'No results',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                        ),
                        if (list.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Tap + to add your first employee',
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
                  itemBuilder: (_, i) => _EmployeeCard(employee: filtered[i], isDark: isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final Employee employee;
  final bool isDark;
  const _EmployeeCard({required this.employee, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(employee.status);

    return GestureDetector(
      onTap: () => context.push(AppRouter.employeeDetail, extra: employee),
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
              Container(width: 3, color: AppColors.accentEmerald),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            employee.firstName.isNotEmpty ? employee.firstName[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.accentEmerald),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(employee.fullName,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.35))),
                                child: Text(employee.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.badge_outlined, size: 11, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(employee.employeeCode, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              if (employee.designation != null) ...[
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: cs.onSurfaceVariant)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(employee.designation!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                              ],
                            ]),
                            if (employee.department != null) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.apartment_outlined, size: 11, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(employee.department!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              ]),
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
                          PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 16, color: cs.onSurface), const SizedBox(width: 10), Text('View', style: TextStyle(fontSize: 13, color: cs.onSurface))])),
                          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: AppColors.accentIndigo), const SizedBox(width: 10), Text('Edit', style: TextStyle(fontSize: 13, color: AppColors.accentIndigo))])),
                          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accentRose), const SizedBox(width: 10), Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.accentRose))])),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return AppColors.accentEmerald;
      case 'Inactive': return AppColors.accentRose;
      default: return AppColors.accentGold;
    }
  }

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'view':
        context.push(AppRouter.employeeDetail, extra: employee);
      case 'edit':
        context.push(AppRouter.createEmployee, extra: employee);
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
        title: Text('Delete Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Delete "${employee.fullName}"? This cannot be undone.', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () {
              ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
