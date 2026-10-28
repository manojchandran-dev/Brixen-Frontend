import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

/// The employee's own app login, in their detail sheet. Activating emails a
/// temporary password to the employee's saved email (plain text); they set
/// their own at first sign-in. Shows whether the setup email went out (or
/// why not), with Resend and Remove. Company admins only; watches the list,
/// so it updates in place.
class EmployeeLoginCard extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeLoginCard({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeLoginCard> createState() => _EmployeeLoginCardState();
}

class _EmployeeLoginCardState extends ConsumerState<EmployeeLoginCard> {
  bool _busy = false;

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.dangerFill : null,
      ),
    );
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _activate(Employee e, {required bool resend}) async {
    final ok = await _confirm(
      resend ? 'Send a new setup email?' : 'Activate login?',
      'A new temporary password will be emailed to ${e.email}. '
      '${resend ? 'Any earlier one stops working. ' : ''}'
      '${e.fullName} sets their own password at first sign-in.',
      resend ? 'Send' : 'Activate',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(employeesProvider.notifier)
          .activateLogin(
            e.id,
            companyId: Session.isSuperAdmin ? e.companyId : null,
          );
      _snack('Setup email sent to ${e.email}');
    } catch (err) {
      _snack(err.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Employee e) async {
    final ok = await _confirm(
      'Remove login?',
      '${e.fullName} will be signed out and can\'t sign in until you activate '
          'their login again.',
      'Remove',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(employeesProvider.notifier)
          .removeLogin(
            e.id,
            companyId: Session.isSuperAdmin ? e.companyId : null,
          );
    } catch (err) {
      _snack(err.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = ref
        .watch(employeesProvider)
        .valueOrNull
        ?.where((x) => x.id == widget.employeeId)
        .firstOrNull;
    if (e == null) return const SizedBox.shrink();
    // Logins are managed by admins, never by an employee login.
    final canEdit =
        Session.role != UserRole.employee &&
        ref.watch(moduleAccessProvider('Employees')).edit;
    final hasEmail = (e.email ?? '').trim().isNotEmpty;
    final failed = e.loginActive && e.setupEmailError != null;
    // The employee's email was changed after the login was set up: they
    // still sign in with the old one until a new password is sent.
    final emailChanged =
        e.loginActive &&
        hasEmail &&
        e.loginEmail != null &&
        e.loginEmail!.toLowerCase() != e.email!.trim().toLowerCase();
    final (IconData icon, Color color, String status) = !e.loginActive
        ? (
            Icons.no_accounts,
            AppColors.textHint,
            e.loginEmail != null
                ? 'Access removed (${e.loginEmail})'
                : 'No login yet',
          )
        : emailChanged
        ? (
            Icons.alternate_email_rounded,
            AppColors.brandDeep,
            'Email changed to ${e.email!.trim()}. They still sign in as '
                '${e.loginEmail} — tap Send new password to move the login '
                'to the new email.',
          )
        : failed
        ? (
            Icons.error_outline_rounded,
            AppColors.dangerFill,
            'Setup email to ${e.loginEmail} failed: ${e.setupEmailError}',
          )
        : e.loginPending
        ? (
            Icons.mark_email_read_outlined,
            AppColors.brandDeep,
            'Setup email sent to ${e.loginEmail}'
                '${e.setupEmailSentAt == null ? '' : ' on ${DateFormat('d MMM, h:mm a').format(e.setupEmailSentAt!.toLocal())}'}'
                ' · waiting for first sign-in',
          )
        : (
            Icons.verified_user_rounded,
            AppColors.positive,
            'Signs in as ${e.loginEmail} with their own password',
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: failed
              ? AppColors.dangerFill.withValues(alpha: 0.5)
              : AppColors.border,
        ),
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
                child: Icon(icon, size: 19, color: color),
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
                      status,
                      style: TextStyle(
                        color: failed
                            ? AppColors.dangerFill
                            : AppColors.textSecondary,
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
              _hint('Only Active employees can sign in.')
            else if (!hasEmail)
              _hint(
                "Add the employee's email (Edit → Personal) — the setup email "
                'with their temporary password goes there.',
              )
            else
              // The main action full width (its label fits); remove and
              // permissions below it.
              BrixenButton(
                label: !e.loginActive
                    ? 'Activate login'
                    : failed
                    ? 'Resend setup email'
                    : 'Send new password',
                isLoading: _busy,
                onPressed: _busy
                    ? null
                    : () => _activate(e, resend: e.loginActive),
              ),
            if (e.loginActive || Session.role == UserRole.companyAdmin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (e.loginActive && e.status == 'Active' && hasEmail)
                    Expanded(
                      child: BrixenButton(
                        label: 'Remove login',
                        isOutlined: true,
                        onPressed: _busy ? null : () => _remove(e),
                      ),
                    ),
                  if (e.loginActive &&
                      e.status == 'Active' &&
                      hasEmail &&
                      Session.role == UserRole.companyAdmin)
                    const SizedBox(width: 10),
                  if (Session.role == UserRole.companyAdmin)
                    Expanded(
                      child: BrixenButton(
                        label: 'Permissions',
                        isOutlined: true,
                        onPressed: () => context.push(
                          AppRouter.staffPermissions,
                          extra: e.id,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _hint(String text) =>
      Text(text, style: TextStyle(color: AppColors.textHint, fontSize: 11.5));
}
