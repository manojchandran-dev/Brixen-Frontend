import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_cubit.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import 'account_switcher_sheet.dart';

String _profileDisplayName() {
  switch (Session.role) {
    case UserRole.superAdmin:
      return 'Admin';
    case UserRole.companyAdmin:
      return Session.ownerName ?? Session.companyName ?? 'Admin';
    case UserRole.employee:
      return Session.email ?? 'Employee';
  }
}

String _profileRoleLabel() {
  switch (Session.role) {
    case UserRole.superAdmin:
      return 'Super Admin';
    case UserRole.companyAdmin:
      return 'Company Admin';
    case UserRole.employee:
      return 'Employee';
  }
}

String _profileInitials(String name) {
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

/// The "More" tab content — profile card, preferences, dark mode, logout.
/// A straight copy of Companies' proven `_MenuBody` (kept there too,
/// untouched) made public and reusable so every role's "More" route can
/// share it without cutting it out of companies_page.dart.
class AppMenuBody extends StatefulWidget {
  const AppMenuBody({super.key});

  @override
  State<AppMenuBody> createState() => _AppMenuBodyState();
}

class _AppMenuBodyState extends State<AppMenuBody> {
  late final StreamSubscription<ThemeMode> _themeSub;

  @override
  void initState() {
    super.initState();
    _themeSub = themeCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _themeSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ── Premium profile card ──────────────────────────────────
        GestureDetector(
          onTap: () => showAccountSwitcher(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.brand, AppColors.positive],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _profileInitials(_profileDisplayName()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileDisplayName(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(label: _profileRoleLabel()),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),

        // ── Preferences ───────────────────────────────────────────
        const _MenuSectionLabel('Preferences'),
        const SizedBox(height: 10),
        _MenuSection(
          items: [
            _MenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              color: AppColors.brand,
              onTap: () => context.push(AppRouter.profile),
            ),
            _MenuItem(
              icon: Icons.key_outlined,
              label: 'Change Password',
              color: AppColors.brandDeep,
              onTap: () => context.push(AppRouter.changePassword),
            ),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'App Lock',
              color: AppColors.brand,
              onTap: () => context.push(AppRouter.security),
            ),
            _MenuItem(
              icon: Icons.help_rounded,
              label: 'Support',
              color: AppColors.positive,
              onTap: () => context.push(AppRouter.support),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DarkModeToggleCard(
          isDark: themeCubit.isDark,
          onChanged: (v) =>
              themeCubit.setMode(v ? ThemeMode.dark : ThemeMode.light),
        ),
        const SizedBox(height: 24),

        // ── Logout ────────────────────────────────────────────────
        GestureDetector(
          onTap: () async {
            await authCubit.signOut();
            if (context.mounted) context.go(AppRouter.signIn);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.highlightShadow(0.9),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ]),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink.withValues(alpha: 0.35),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // ── Footer ────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Brix',
                      style: TextStyle(color: AppColors.brand),
                    ),
                    const TextSpan(
                      text: 'en',
                      style: TextStyle(color: AppColors.positive),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 12, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSectionLabel extends StatelessWidget {
  final String label;
  const _MenuSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.highlightShadow(0.9),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ]),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.ink.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: AppColors.border, indent: 66),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _DarkModeToggleCard extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _DarkModeToggleCard({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.9),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ]),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandDeep.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                size: 18,
                color: AppColors.brandDeep,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Dark mode',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: isDark,
              activeThumbColor: AppColors.brand,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
