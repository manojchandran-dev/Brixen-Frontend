import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/page_header_bar.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/profile_model.dart';

/// This page is always reached via `context.push` from More — tapping the
/// bottom nav's own "More" icon should just pop back to that existing page
/// instead of `context.go`-ing to a brand new one (which tears down and
/// rebuilds the whole route stack). Dashboard/Report aren't a "back"
/// relationship here, so those still go normally.
void _onNavTap(BuildContext context, int index) {
  if (index == 3) {
    context.pop();
    return;
  }
  context.go(index == 2 ? AppRouter.report : AppRouter.dashboard);
}

String _displayName(ProfileModel p) {
  if (p.isSuperAdmin) return 'Admin';
  if (p.isCompany) return p.ownerName ?? p.companyName ?? 'Admin';
  return p.email;
}

String _roleLabel(ProfileModel p) {
  if (p.isSuperAdmin) return 'Super Admin';
  if (p.isCompany) return 'Company Admin';
  return 'Employee';
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

/// "My profile" — fetched live from `GET /auth/me` (not just what
/// [Session] cached at login), with an edit mode for the roles the backend
/// actually supports editing (`PUT /auth/me`): company accounts can update
/// owner name/phone/secondary email/website, superAdmin can update email.
/// Employee accounts have no editable fields on this endpoint, so they
/// stay view-only.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _editing = false;
  bool _saving = false;
  String? _error;

  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _secondaryEmailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startEdit(ProfileModel p) {
    _ownerNameCtrl.text = p.ownerName ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _secondaryEmailCtrl.text = p.secondaryEmail ?? '';
    _websiteCtrl.text = p.website ?? '';
    _emailCtrl.text = p.email;
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  Future<void> _save(ProfileModel p) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final fields = p.isSuperAdmin
          ? {'email': _emailCtrl.text.trim()}
          : {
              'owner_name': _ownerNameCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'secondary_email': _secondaryEmailCtrl.text.trim(),
              'website': _websiteCtrl.text.trim(),
            };
      await ref.read(profileRemoteDatasourceProvider).updateProfile(fields);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.positive,
        ),
      );
    } catch (e) {
      setState(
        () => _error = e is ApiException
            ? e.message
            : 'Could not update profile.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileProvider);
    return AppShell(
      activeIndex: 3,
      onNavTap: (i) => _onNavTap(context, i),
      body: Column(
        children: [
          PageHeaderBar(
            title: 'Profile',
            trailing: async.maybeWhen(
              data: (p) => (p.isCompany || p.isSuperAdmin) && !_editing
                  ? GestureDetector(
                      onTap: () => _startEdit(p),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.brand,
                        ),
                      ),
                    )
                  : null,
              orElse: () => null,
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e is ApiException ? e.message : 'Could not load profile.',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
              data: (p) => _editing
                  ? _EditForm(
                      profile: p,
                      ownerNameCtrl: _ownerNameCtrl,
                      phoneCtrl: _phoneCtrl,
                      secondaryEmailCtrl: _secondaryEmailCtrl,
                      websiteCtrl: _websiteCtrl,
                      emailCtrl: _emailCtrl,
                      error: _error,
                      saving: _saving,
                      onCancel: () => setState(() => _editing = false),
                      onSave: () => _save(p),
                    )
                  : _ViewBody(profile: p),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewBody extends StatelessWidget {
  final ProfileModel profile;
  const _ViewBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = _displayName(profile);
    final rows = <(IconData, String, String?)>[
      (Icons.mail_outline_rounded, 'Email', profile.email),
      if (profile.isCompany) ...[
        (Icons.apartment_rounded, 'Company', profile.companyName),
        (Icons.badge_outlined, 'Owner Name', profile.ownerName),
        (Icons.call_outlined, 'Phone', profile.phone),
        (
          Icons.alternate_email_rounded,
          'Secondary Email',
          profile.secondaryEmail,
        ),
        (Icons.language_rounded, 'Website', profile.website),
      ],
      if (!profile.isCompany &&
          !profile.isSuperAdmin &&
          Session.employeeId != null)
        (Icons.badge_outlined, 'Employee ID', Session.employeeId),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _ProfileHero(name: name, roleLabel: _roleLabel(profile)),
        const SizedBox(height: 20),
        for (final (icon, label, value) in rows)
          if (value != null && value.isNotEmpty)
            _InfoTile(icon: icon, label: label, value: value),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String roleLabel;
  const _ProfileHero({required this.name, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.brand, AppColors.positive],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: AppColors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _EditForm extends StatelessWidget {
  final ProfileModel profile;
  final TextEditingController ownerNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController secondaryEmailCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController emailCtrl;
  final String? error;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditForm({
    required this.profile,
    required this.ownerNameCtrl,
    required this.phoneCtrl,
    required this.secondaryEmailCtrl,
    required this.websiteCtrl,
    required this.emailCtrl,
    required this.error,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (profile.isSuperAdmin)
          BrixenTextField(
            label: 'Email',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
          )
        else ...[
          BrixenTextField(label: 'Owner Name', controller: ownerNameCtrl),
          const SizedBox(height: 14),
          BrixenTextField(
            label: 'Phone',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          BrixenTextField(
            label: 'Secondary Email',
            controller: secondaryEmailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          BrixenTextField(
            label: 'Website',
            controller: websiteCtrl,
            keyboardType: TextInputType.url,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: BrixenButton(
                label: 'Cancel',
                isOutlined: true,
                onPressed: saving ? null : onCancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BrixenButton(
                label: 'Save',
                isLoading: saving,
                onPressed: saving ? null : onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brand, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
