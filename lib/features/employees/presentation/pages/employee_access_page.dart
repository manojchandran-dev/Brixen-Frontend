import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

const _actions = ['view', 'create', 'edit', 'delete'];
const _actionLabels = {
  'view': 'View',
  'create': 'Add',
  'edit': 'Edit',
  'delete': 'Delete',
};

/// One module an employee can be given: what the company may do there
/// (the ceiling) and what this employee currently may.
class _ModuleGrant {
  final String id, name;
  final String? group;
  final Map<String, bool> company;
  final Map<String, bool> employee;
  _ModuleGrant(this.id, this.name, this.group, this.company, this.employee);

  factory _ModuleGrant.fromJson(Map<String, dynamic> j) {
    Map<String, bool> flags(dynamic m) => {
      for (final a in _actions) a: (m is Map && m[a] == true),
    };
    return _ModuleGrant(
      j['id'].toString(),
      (j['name'] ?? '').toString(),
      j['group']?.toString(),
      flags(j['company']),
      flags(j['employee']),
    );
  }
}

final _grantsProvider = FutureProvider.autoDispose
    .family<List<_ModuleGrant>, String>((ref, employeeId) async {
      try {
        final resp = await ref
            .read(dioProvider)
            .get(ApiEndpoints.employeePermissions(employeeId));
        final data = (resp.data['data'] ?? resp.data) as Map;
        return [
          for (final m in (data['modules'] as List? ?? const []))
            _ModuleGrant.fromJson((m as Map).cast<String, dynamic>()),
        ];
      } on DioException catch (e) {
        throw mapDioError(e);
      }
    });

/// Company admins choose which of their company's modules each employee may
/// use, and what they may do there. Only modules the company has are
/// listed; an action the company itself may not do can't be given. The
/// server checks the same, on every request the employee makes.
class EmployeeAccessPage extends ConsumerStatefulWidget {
  final String? initialEmployeeId;
  const EmployeeAccessPage({super.key, this.initialEmployeeId});

  @override
  ConsumerState<EmployeeAccessPage> createState() => _EmployeeAccessPageState();
}

class _EmployeeAccessPageState extends ConsumerState<EmployeeAccessPage> {
  late String? _employeeId = widget.initialEmployeeId;

  /// Edits not saved yet, per module id; null = as loaded.
  Map<String, Map<String, bool>>? _draft;
  bool _saving = false;

  void _select(Employee? e) => setState(() {
    _employeeId = e?.id;
    _draft = null;
  });

  Map<String, Map<String, bool>> _working(List<_ModuleGrant> grants) =>
      _draft ??
      {for (final g in grants) g.id: Map<String, bool>.from(g.employee)};

  void _toggle(List<_ModuleGrant> grants, _ModuleGrant g, String action) {
    final w = _working(grants);
    final flags = Map<String, bool>.from(w[g.id]!);
    final on = !(flags[action] ?? false);
    flags[action] = on;
    // Add / Edit / Delete need View; no View means nothing else.
    if (on && action != 'view') flags['view'] = true;
    if (!on && action == 'view') {
      for (final a in _actions) {
        flags[a] = false;
      }
    }
    setState(() => _draft = {...w, g.id: flags});
  }

  Future<void> _save(List<_ModuleGrant> grants) async {
    final w = _working(grants);
    setState(() => _saving = true);
    try {
      await ref
          .read(dioProvider)
          .put(
            ApiEndpoints.employeePermissions(_employeeId!),
            data: {
              'permissions': [
                for (final g in grants)
                  if (w[g.id]!['view'] == true)
                    {'module_id': g.id, ...w[g.id]!},
              ],
            },
          );
      ref.invalidate(_grantsProvider(_employeeId!));
      setState(() => _draft = null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Access saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((e is DioException ? mapDioError(e) : e).toString()),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(moduleAccessProvider('Employees')).edit;
    final employees = [
      for (final e
          in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
        if (e.status == 'Active') e,
    ];
    final selected = employees.where((e) => e.id == _employeeId).firstOrNull;
    final grants = _employeeId == null
        ? null
        : ref.watch(_grantsProvider(_employeeId!));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const ModuleTitle(
          title: 'Employee Access',
          subtitle: 'What each employee can use',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          BrixenDropdown<Employee>(
            hint: 'Employee',
            value: selected,
            items: employees,
            labelOf: (e) => e.fullName,
            subtitleOf: (e) => [
              e.employeeCode,
              if (e.department != null) e.department!,
              e.loginActive ? 'Can sign in' : 'No login yet',
            ].join(' · '),
            icon: Icons.person_search_rounded,
            onChanged: _select,
          ),
          const SizedBox(height: 10),
          Text(
            'Only modules your company has are listed. An action your company '
            "can't do can't be given.",
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          if (selected != null && !selected.loginActive) ...[
            const SizedBox(height: 10),
            _Note(
              '${selected.fullName} can\'t sign in yet — activate their login '
              'in Employees. Access set here applies once they do.',
            ),
          ],
          const SizedBox(height: 16),
          if (grants == null)
            const _Note('Pick an employee to see and change their access.')
          else
            grants.when(
              skipError: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(_grantsProvider(_employeeId!)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _Note(
                    'Your company has no modules to share yet. Your platform '
                    'admin grants modules to your company.',
                  );
                }
                final w = _working(list);
                return Column(
                  children: [
                    for (final g in list)
                      _ModuleTile(
                        grant: g,
                        flags: w[g.id]!,
                        enabled: canEdit && !_saving,
                        onToggle: (a) => _toggle(list, g, a),
                      ),
                    const SizedBox(height: 16),
                    if (canEdit)
                      BrixenButton(
                        label: 'Save access',
                        isLoading: _saving,
                        onPressed: _saving || _draft == null
                            ? null
                            : () => _save(list),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _ModuleGrant grant;
  final Map<String, bool> flags;
  final bool enabled;
  final ValueChanged<String> onToggle;
  const _ModuleTile({
    required this.grant,
    required this.flags,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final on = flags['view'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? AppColors.brand.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: grant.name,
                    children: [
                      if (grant.group != null)
                        TextSpan(
                          text: '  ·  ${grant.group}',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                on ? 'Allowed' : 'No access',
                style: TextStyle(
                  color: on ? AppColors.positive : AppColors.textHint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in _actions)
                FilterChip(
                  label: Text(_actionLabels[a]!),
                  selected: flags[a] == true,
                  // Greyed out when the company can't do it.
                  onSelected: enabled && grant.company[a] == true
                      ? (_) => onToggle(a)
                      : null,
                  tooltip: grant.company[a] == true
                      ? null
                      : "Your company can't ${_actionLabels[a]!.toLowerCase()} here",
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
    ),
  );
}
