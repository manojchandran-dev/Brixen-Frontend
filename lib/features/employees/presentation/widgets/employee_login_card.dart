import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

/// The employee's own app login, in their detail sheet: whether they have
/// one, its email, and (for an admin who may edit employees) buttons to set
/// it up, change it or remove it. Watches the list, so it updates in place.
class EmployeeLoginCard extends ConsumerWidget {
  final String employeeId;
  const EmployeeLoginCard({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref
        .watch(employeesProvider)
        .valueOrNull
        ?.where((x) => x.id == employeeId)
        .firstOrNull;
    if (e == null) return const SizedBox.shrink();
    final canEdit = ref.watch(moduleAccessProvider('Employees')).edit;
    final active = e.loginActive;
    final color = active ? AppColors.positive : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  active ? Icons.verified_user_rounded : Icons.no_accounts,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App login',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      active
                          ? 'Signs in as ${e.loginEmail} · sees only their own profile and attendance'
                          : e.loginEmail != null
                          ? 'Access removed (${e.loginEmail})'
                          : 'No login yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            if (e.status != 'Active')
              Text(
                'Only Active employees can sign in.',
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: BrixenButton(
                      label: active ? 'Change login' : 'Set up login',
                      onPressed: () => _openLoginSheet(context, ref, e),
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrixenButton(
                        label: 'Remove',
                        isOutlined: true,
                        onPressed: () => _remove(context, ref, e),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Employee e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Remove login?'),
        content: Text(
          '${e.fullName} will be signed out and can\'t sign in until you set '
          'a login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(employeesProvider.notifier)
          .removeLogin(
            e.id,
            companyId: Session.isSuperAdmin ? e.companyId : null,
          );
    } catch (err) {
      if (context.mounted) _snack(context, err.toString());
    }
  }
}

void _snack(BuildContext context, String text, {bool error = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.dangerFill : null,
    ),
  );
}

Future<void> _openLoginSheet(BuildContext context, WidgetRef ref, Employee e) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginSheet(employee: e),
    );

class _LoginSheet extends ConsumerStatefulWidget {
  final Employee employee;
  const _LoginSheet({required this.employee});

  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(
    text: widget.employee.loginEmail ?? widget.employee.email ?? '',
  );
  final _password = TextEditingController();
  bool _saving = false;

  /// A password is needed to create a login; changing one may keep it.
  bool get _hasLogin => widget.employee.loginActive;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(employeesProvider.notifier)
          .setLogin(
            widget.employee.id,
            email: _email.text.trim(),
            password: _password.text,
            companyId: Session.isSuperAdmin ? widget.employee.companyId : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(
        context,
        '${widget.employee.fullName} can now sign in with ${_email.text.trim()}',
        error: false,
      );
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasLogin ? 'Change login' : 'Set up login',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.employee.fullName} signs in to the app with this '
                'email and password, and sees only their own profile and '
                'attendance.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 18),
              BrixenTextField(
                label: 'Login email *',
                hint: 'name@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Enter an email';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              BrixenTextField(
                label: _hasLogin ? 'New password' : 'Password *',
                hint: _hasLogin
                    ? 'Leave empty to keep the current one'
                    : 'At least 8 characters',
                controller: _password,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return _hasLogin ? null : 'Set a password';
                  if (s.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              if (_hasLogin) ...[
                const SizedBox(height: 6),
                Text(
                  'A new password signs them out on every device.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
              const SizedBox(height: 20),
              BrixenButton(
                label: 'Save login',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
