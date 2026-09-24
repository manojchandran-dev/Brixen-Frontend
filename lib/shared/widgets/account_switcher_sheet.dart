import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/services/account_store.dart';
import '../../core/services/token_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// Opens the Gmail-style account switcher — every account signed into on
/// this device (see [AccountStore]), plus "Add account". Call from a tap on
/// the "More" tab's profile card.
///
/// Snapshots whatever's currently active first: [AccountStore] otherwise
/// only learns about an account when it's freshly signed into via
/// [AuthCubit.signIn], so a session already active before this feature
/// shipped (or restored from disk on app launch) would never appear here
/// on its own — and get silently lost the moment "Add account" clears it
/// to sign into the next one. Doing it here instead of only on sign-in
/// makes it self-healing regardless of how the active session got there.
Future<void> showAccountSwitcher(BuildContext context) async {
  await AccountStore.upsertCurrent();
  if (!context.mounted) return;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AccountSwitcherSheet(),
  );
}

String _displayName(AccountSnapshot a) {
  switch (UserRoleX.fromString(a.userType ?? a.role)) {
    case UserRole.superAdmin:
      return 'Admin';
    case UserRole.companyAdmin:
      return a.ownerName ?? a.companyName ?? 'Admin';
    case UserRole.employee:
      return a.email;
  }
}

String _roleLabel(AccountSnapshot a) {
  switch (UserRoleX.fromString(a.userType ?? a.role)) {
    case UserRole.superAdmin:
      return 'Super Admin';
    case UserRole.companyAdmin:
      return 'Company Admin';
    case UserRole.employee:
      return 'Employee';
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

class _AccountSwitcherSheet extends StatefulWidget {
  const _AccountSwitcherSheet();

  @override
  State<_AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<_AccountSwitcherSheet> {
  bool _busy = false;

  Future<void> _switchTo(String email) async {
    if (_busy || email == TokenService.email) return;
    setState(() => _busy = true);
    final switched = await authCubit.switchAccount(email);
    if (!mounted) return;
    if (!switched) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session for $email has expired — sign in again.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    context.go(AppRouter.dashboard);
  }

  Future<void> _removeAccount(String email) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          'You\'ll need to sign in again to use $email on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AccountStore.remove(email);
    if (mounted) setState(() {});
  }

  void _addAccount() {
    if (_busy) return;
    Navigator.of(context).pop();
    // Plain push, no session change here — AuthCubit.signIn() only touches
    // TokenService once the new login actually succeeds, so backing out of
    // this leaves the current account untouched.
    context.push(AppRouter.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountStore.accounts;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ]),
          ),
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
                'Switch account',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final a in accounts)
                _AccountRow(
                  account: a,
                  active: a.email == TokenService.email,
                  onTap: () => _switchTo(a.email),
                  onRemove: a.email == TokenService.email
                      ? null
                      : () => _removeAccount(a.email),
                ),
              if (accounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: AppColors.border),
                ),
              GestureDetector(
                onTap: _addAccount,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Add account',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 6),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountSnapshot account;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _AccountRow({
    required this.account,
    required this.active,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = _displayName(account);
    // Normal tap switches into the account; long-press (only offered for a
    // non-active one — see onRemove's null check upstream) asks to remove
    // it instead, so the two actions share the row without a dedicated
    // remove button crowding it.
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.positive],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _roleLabel(account),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                  Text(
                    account.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.positive,
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink.withValues(alpha: 0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
