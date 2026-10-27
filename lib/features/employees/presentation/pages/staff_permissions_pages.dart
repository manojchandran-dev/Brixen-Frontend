import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../navigation/presentation/module_visuals.dart';
import '../../../permissions/domain/entities/module_permission.dart'
    show AccessLevel, AccessLevelX;
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

// Staff Permissions: a company admin decides which of the company's modules
// each employee may use, and what they may do there — the same screens as
// the superadmin's Permissions (employee list → modules → one module), with
// one rule on top: an employee never gets more than the company has. The
// server checks the same on every request the employee makes.

const _actions = ['view', 'create', 'edit', 'delete'];

/// One module an employee can be given: what the company may do there (the
/// ceiling) and what this employee may.
class StaffModuleGrant {
  final String id, name;
  final String? group;
  final Map<String, bool> company;
  final Map<String, bool> employee;
  const StaffModuleGrant(
    this.id,
    this.name,
    this.group,
    this.company,
    this.employee,
  );

  factory StaffModuleGrant.fromJson(Map<String, dynamic> j) {
    Map<String, bool> flags(dynamic m) => {
      for (final a in _actions) a: (m is Map && m[a] == true),
    };
    return StaffModuleGrant(
      j['id'].toString(),
      (j['name'] ?? '').toString(),
      j['group']?.toString(),
      flags(j['company']),
      flags(j['employee']),
    );
  }

  /// Everything the company allows here (what "Full Access" gives).
  Map<String, bool> get fullFlags => {
    for (final a in _actions) a: company[a] == true,
  };

  AccessLevel levelOf(Map<String, bool> f) {
    if (f['view'] != true) return AccessLevel.none;
    return _actions.every((a) => f[a] == fullFlags[a])
        ? AccessLevel.full
        : AccessLevel.custom;
  }

  StaffModuleGrant withEmployee(Map<String, bool> f) =>
      StaffModuleGrant(id, name, group, company, f);
}

/// An employee's grants, with saving of one module at a time.
final staffGrantsProvider = AsyncNotifierProvider.autoDispose
    .family<StaffGrantsNotifier, List<StaffModuleGrant>, String>(
      StaffGrantsNotifier.new,
    );

class StaffGrantsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<StaffModuleGrant>, String> {
  List<StaffModuleGrant> _parse(dynamic body) {
    final data = (body is Map ? (body['data'] ?? body) : body) as Map;
    return [
      for (final m in (data['modules'] as List? ?? const []))
        StaffModuleGrant.fromJson((m as Map).cast<String, dynamic>()),
    ];
  }

  @override
  Future<List<StaffModuleGrant>> build(String employeeId) async {
    try {
      final resp = await ref
          .read(dioProvider)
          .get(ApiEndpoints.employeePermissions(employeeId));
      return _parse(resp.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Saves [moduleId] as [flags], keeping every other module as it is.
  Future<void> saveModule(String moduleId, Map<String, bool> flags) async {
    final current = state.valueOrNull ?? await future;
    final next = [
      for (final g in current) g.id == moduleId ? g.withEmployee(flags) : g,
    ];
    try {
      final resp = await ref
          .read(dioProvider)
          .put(
            ApiEndpoints.employeePermissions(arg),
            data: {
              'permissions': [
                for (final g in next)
                  if (g.employee['view'] == true)
                    {'module_id': g.id, ...g.employee},
              ],
            },
          );
      state = AsyncData(_parse(resp.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

// ── 1. Employees ──────────────────────────────────────────────────────────

/// Every active employee, with how many modules they have and whether they
/// can sign in; tap one for their modules.
class StaffPermissionsPage extends ConsumerStatefulWidget {
  /// Opens straight to this employee's modules (from their detail sheet).
  final String? initialEmployeeId;
  const StaffPermissionsPage({super.key, this.initialEmployeeId});

  @override
  ConsumerState<StaffPermissionsPage> createState() =>
      _StaffPermissionsPageState();
}

class _StaffPermissionsPageState extends ConsumerState<StaffPermissionsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final id = widget.initialEmployeeId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final all = await ref.read(employeesProvider.future);
        final e = all.where((x) => x.id == id).firstOrNull;
        if (e != null && mounted) _open(e);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Employee e) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => StaffModulesPage(employee: e)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(employeesProvider);
    final q = _query.trim().toLowerCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const ModuleTitle(
          title: 'Staff Permissions',
          subtitle: 'What each employee can use',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _search,
              hintText: 'Search employee',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: async.when(
              skipError: true,
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(employeesProvider),
              ),
              data: (all) {
                final list = [
                  for (final e in all)
                    if (e.status == 'Active' &&
                        (q.isEmpty ||
                            '${e.fullName} ${e.employeeCode} ${e.department ?? ''}'
                                .toLowerCase()
                                .contains(q)))
                      e,
                ];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      q.isEmpty
                          ? 'No active employees yet'
                          : 'No employees match',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EmployeeCard(
                    employee: list[i],
                    index: i,
                    onTap: () => _open(list[i]),
                  ),
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
  final int index;
  final VoidCallback onTap;
  const _EmployeeCard({
    required this.employee,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = employee;
    final accent = RichCardShell.accentFor(index);
    final granted = ref
        .watch(staffGrantsProvider(e.id))
        .valueOrNull
        ?.where((g) => g.employee['view'] == true)
        .length;
    return RichCardShell(
      accentColor: accent,
      showAccentBar: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(accent),
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                e.fullName.isEmpty ? '?' : e.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    [
                      e.employeeCode,
                      if (e.department != null) e.department!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _Chip(
                        e.loginActive ? 'Can sign in' : 'No login yet',
                        e.loginActive ? AppColors.positive : AppColors.textHint,
                      ),
                      if (granted != null)
                        _Chip(
                          '$granted module${granted == 1 ? '' : 's'}',
                          AppColors.brand,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

// ── 2. One employee's modules ─────────────────────────────────────────────

/// The company's modules for one employee, grouped like the superadmin's
/// Permissions (Modules, Masters), each with its access level.
class StaffModulesPage extends ConsumerWidget {
  final Employee employee;
  const StaffModulesPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffGrantsProvider(employee.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.fullName,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Staff permissions',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
      body: async.when(
        skipError: true,
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (e, _) => ErrorCard(
          error: e,
          onRetry: () => ref.invalidate(staffGrantsProvider(employee.id)),
        ),
        data: (grants) {
          final groups = <String, List<StaffModuleGrant>>{};
          for (final g in grants) {
            groups.putIfAbsent(g.group ?? 'Modules', () => []).add(g);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (!employee.loginActive)
                _Note(
                  "${employee.fullName} can't sign in yet — activate their "
                  'login in Employees. What you set here applies once they do.',
                ),
              if (grants.isEmpty)
                const _Note(
                  'Your company has no modules to share yet. Your platform '
                  'admin grants modules to your company.',
                ),
              for (final entry in groups.entries) ...[
                const SizedBox(height: 12),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                for (final g in entry.value) ...[
                  _ModuleRow(
                    grant: g,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StaffModuleAccessPage(
                          employee: employee,
                          moduleId: g.id,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

Color _levelColor(AccessLevel l) => switch (l) {
  AccessLevel.full => AppColors.positive,
  AccessLevel.custom => AppColors.brand,
  AccessLevel.none => AppColors.textHint,
};

class _ModuleRow extends StatelessWidget {
  final StaffModuleGrant grant;
  final VoidCallback onTap;
  const _ModuleRow({required this.grant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = moduleVisualFor(grant.name);
    final level = grant.levelOf(grant.employee);
    final c = _levelColor(level);
    return RichCardShell(
      accentColor: visual.color,
      showAccentBar: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(visual.color),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visual.icon, size: 18, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grant.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final a in _actions)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: grant.employee[a] == true
                                ? AppColors.positive
                                : Colors.transparent,
                            border: grant.employee[a] == true
                                ? null
                                : Border.all(
                                    color: AppColors.border,
                                    width: 1.2,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                level.label,
                style: TextStyle(
                  color: c,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. One module ─────────────────────────────────────────────────────────

/// Access level and the four permissions for one module, like the
/// superadmin's Module Access. What the company can't do is locked off.
class StaffModuleAccessPage extends ConsumerStatefulWidget {
  final Employee employee;
  final String moduleId;
  const StaffModuleAccessPage({
    super.key,
    required this.employee,
    required this.moduleId,
  });

  @override
  ConsumerState<StaffModuleAccessPage> createState() =>
      _StaffModuleAccessPageState();
}

class _StaffModuleAccessPageState extends ConsumerState<StaffModuleAccessPage> {
  Map<String, bool>? _flags;
  bool _saving = false;

  void _setLevel(StaffModuleGrant g, AccessLevel level) => setState(() {
    _flags = switch (level) {
      AccessLevel.none => {for (final a in _actions) a: false},
      AccessLevel.full => g.fullFlags,
      // Custom starts from View only, then the switches below.
      AccessLevel.custom => {
        for (final a in _actions) a: a == 'view' && g.company['view'] == true,
      },
    };
  });

  void _setFlag(String action, bool on) => setState(() {
    final f = Map<String, bool>.from(_flags!);
    f[action] = on;
    // Create / Edit / Delete need View; no View means nothing else.
    if (on && action != 'view') f['view'] = true;
    if (!on && action == 'view') {
      for (final a in _actions) {
        f[a] = false;
      }
    }
    _flags = f;
  });

  Future<void> _apply(StaffModuleGrant g) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(staffGrantsProvider(widget.employee.id).notifier)
          .saveModule(g.id, _flags!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${g.name} access updated')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(moduleAccessProvider('Employees')).edit;
    final g = ref
        .watch(staffGrantsProvider(widget.employee.id))
        .valueOrNull
        ?.where((x) => x.id == widget.moduleId)
        .firstOrNull;
    final appBar = AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Module Access',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (g == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }
    final flags = _flags ??= Map<String, bool>.from(g.employee);
    final level = g.levelOf(flags);
    final locked = level != AccessLevel.custom || !canEdit;
    final visual = moduleVisualFor(g.name);
    final name = g.name.toLowerCase();

    Widget toggle(String a, IconData icon, String title, String subtitle) {
      final allowed = g.company[a] == true;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _Toggle(
          icon: icon,
          color: a == 'delete' ? AppColors.brandBlack : AppColors.brand,
          title: title,
          subtitle: allowed
              ? subtitle
              : "Your company can't ${title.toLowerCase()} here",
          value: flags[a] == true,
          enabled: !locked && allowed,
          onChanged: (v) => _setFlag(a, v),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient(
                        visual.color,
                      ).map((c) => c.withValues(alpha: 0.12)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: visual.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.accentGradient(visual.color),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(visual.icon, size: 26, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'For ${widget.employee.fullName}',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Label('Access Level'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final l in AccessLevel.values) ...[
                      Expanded(
                        child: _LevelCard(
                          level: l,
                          selected: level == l,
                          onTap: canEdit ? () => _setLevel(g, l) : null,
                        ),
                      ),
                      if (l != AccessLevel.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _Label('Permissions'),
                const SizedBox(height: 10),
                toggle(
                  'view',
                  Icons.visibility_outlined,
                  'View',
                  'View $name data',
                ),
                toggle(
                  'create',
                  Icons.add_rounded,
                  'Create',
                  'Create new $name',
                ),
                toggle(
                  'edit',
                  Icons.edit_outlined,
                  'Edit',
                  'Edit existing $name',
                ),
                toggle(
                  'delete',
                  Icons.delete_outline,
                  'Delete',
                  'Delete $name',
                ),
                Text(
                  'Full Access gives everything your company can do here.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (canEdit)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: BrixenButton(
                  label: 'Apply Changes',
                  isLoading: _saving,
                  onPressed: _saving ? null : () => _apply(g),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _LevelCard extends StatelessWidget {
  final AccessLevel level;
  final bool selected;
  final VoidCallback? onTap;
  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = _levelColor(level);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(level.icon, color: c, size: 22),
            const SizedBox(height: 8),
            Text(
              level.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool value, enabled;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled || value ? 1 : 0.6,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.positive,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
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
