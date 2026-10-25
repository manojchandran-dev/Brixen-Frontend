import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/services/account_store.dart';
import '../../core/services/token_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/security/presentation/pages/confirm_identity_sheet.dart';

/// Opens the Gmail-style account switcher — every account signed into on
/// this device (see [AccountStore]), plus "Add another account". Call from a
/// tap on the "More" tab's profile card.
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

/// Name shown for a saved account.
String accountDisplayName(AccountSnapshot a) {
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
  final role = switch (UserRoleX.fromString(a.userType ?? a.role)) {
    UserRole.superAdmin => 'Super Admin',
    UserRole.companyAdmin => 'Company Admin',
    UserRole.employee => 'Employee',
  };
  final company = a.companyName;
  return company == null || company.isEmpty ? role : '$role · $company';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'[\s@.]+'))
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

/// Switches to [email] from anywhere (switcher sheet, sign-in page) and
/// returns whether it switched; the caller then goes to the dashboard. If
/// that account's session has ended, the current account stays active and a
/// snack bar offers to sign in to it again.
Future<bool> switchToAccount(BuildContext context, String email) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final result = await authCubit.switchAccount(email);
  switch (result) {
    case SwitchResult.switched:
      return true;
    case SwitchResult.expired:
      messenger.showSnackBar(
        SnackBar(
          content: Text('$email was signed out. Sign in to use it again.'),
          action: SnackBarAction(
            label: 'Sign in',
            onPressed: () => router.push(AppRouter.signIn, extra: email),
          ),
        ),
      );
      return false;
    case SwitchResult.notFound:
      return false;
  }
}

class _AccountSwitcherSheet extends StatefulWidget {
  const _AccountSwitcherSheet();

  @override
  State<_AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<_AccountSwitcherSheet> {
  /// The account being switched to, while it happens.
  String? _switching;

  Future<void> _switchTo(String email) async {
    if (_switching != null || email == TokenService.email) return;
    // Fingerprint (or this device's PIN) before handing over another
    // account's data.
    if (!await confirmIdentity(context) || !mounted) return;
    setState(() => _switching = email);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final switched = await switchToAccount(context, email);
    if (!mounted) return;
    // Closed either way: on failure the "Sign in" snack bar would otherwise
    // sit hidden behind the sheet.
    navigator.pop();
    if (switched) router.go(AppRouter.dashboard);
  }

  Future<void> _removeAccount(AccountSnapshot a) async {
    if (_switching != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          '${a.email} will be removed from this device. You can sign in '
          'to it again any time.',
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
    await AccountStore.remove(a.email);
    if (mounted) setState(() {});
  }

  void _addAccount() {
    if (_switching != null) return;
    Navigator.of(context).pop();
    // Plain push, no session change here — AuthCubit.signIn() only touches
    // TokenService once the new login actually succeeds, so backing out of
    // this leaves the current account untouched.
    context.push(AppRouter.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountStore.accounts;
    final activeEmail = TokenService.email;
    final active = accounts.where((a) => a.email == activeEmail).firstOrNull;
    final others = [
      for (final a in accounts.reversed)
        if (a.email != activeEmail) a,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
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
                'Accounts',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                others.isEmpty
                    ? 'Add another account to switch between them'
                    : 'Tap an account to switch to it',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active != null) _ActiveAccountCard(account: active),
                      if (others.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'OTHER ACCOUNTS',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        for (final a in others)
                          _AccountRow(
                            account: a,
                            switching: _switching == a.email,
                            enabled: _switching == null,
                            onTap: () => _switchTo(a.email),
                            onRemove: () => _removeAccount(a),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _switching == null ? _addAccount : null,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text('Add another account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar(this.name, {this.size = 42});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brand, AppColors.brandDeep],
      ),
      shape: BoxShape.circle,
    ),
    child: Text(
      _initials(name),
      style: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.33,
      ),
    ),
  );
}

/// The signed-in account, highlighted at the top.
class _ActiveAccountCard extends StatelessWidget {
  final AccountSnapshot account;
  const _ActiveAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final name = accountDisplayName(account);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _Avatar(name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleLabel(account),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.positive,
                ),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    color: AppColors.positive,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountSnapshot account;
  final bool switching;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _AccountRow({
    required this.account,
    required this.switching,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = accountDisplayName(account);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 0, 10),
          child: Row(
            children: [
              _Avatar(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      switching ? 'Switching…' : _roleLabel(account),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: switching
                            ? AppColors.brand
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (switching)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<String>(
                  enabled: enabled,
                  tooltip: 'More',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textHint,
                  ),
                  onSelected: (_) => onRemove(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Remove from this device'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
