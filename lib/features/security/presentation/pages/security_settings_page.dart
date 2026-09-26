import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/module_title.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';
import 'set_pin_page.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SecurityCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBottomNav fills the Scaffold height (its pill is Align-ed to the
      // bottom) — without extendBody the body gets zero height.
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]),
              ),
              child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ),
        title: const ModuleTitle(
          title: 'App Lock',
          subtitle: 'Keep the app locked when you leave it',
        ),
      ),
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          if (state.status == SecurityStatus.initial ||
              state.status == SecurityStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final cubit = context.read<SecurityCubit>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _StatusBanner(
                on: state.isPinEnabled,
                withBiometric: state.isPinEnabled && state.isBiometricEnabled,
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Lock methods'),
              const SizedBox(height: 10),
              _Group(
                tiles: [
                  _Tile(
                    icon: Icons.pin_rounded,
                    color: AppColors.brand,
                    title: 'PIN Lock',
                    subtitle: state.isPinEnabled
                        ? 'On — a 6-digit PIN unlocks the app'
                        : 'Off — set a 6-digit PIN to turn it on',
                    trailing: Switch.adaptive(
                      value: state.isPinEnabled,
                      activeTrackColor: AppColors.brand,
                      onChanged: (val) {
                        if (val) {
                          showSetPinSheet(context);
                        } else {
                          cubit.disablePin();
                        }
                      },
                    ),
                  ),
                  if (state.isPinEnabled)
                    _Tile(
                      icon: Icons.password_rounded,
                      color: AppColors.brandDeep,
                      title: 'Change PIN',
                      subtitle: 'Update your 6-digit PIN',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                      onTap: () => showSetPinSheet(context),
                    ),
                  if (state.isBiometricAvailable)
                    _Tile(
                      icon: Icons.fingerprint_rounded,
                      color: AppColors.positive,
                      title: 'Fingerprint',
                      subtitle: state.isPinEnabled
                          ? 'Unlock with your fingerprint instead of the PIN'
                          : 'Turn on PIN Lock first',
                      trailing: Switch.adaptive(
                        value: state.isBiometricEnabled,
                        activeTrackColor: AppColors.positive,
                        onChanged: state.isPinEnabled
                            ? (val) => cubit.setBiometric(val)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'When App Lock is on, you\'ll be asked to verify it\'s you each time you open the app.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top banner: whether App Lock is on, at a glance.
class _StatusBanner extends StatelessWidget {
  final bool on;
  final bool withBiometric;
  const _StatusBanner({required this.on, required this.withBiometric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: on
              ? const [AppColors.brand, AppColors.positive]
              : [AppColors.brandBlack, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: (on ? AppColors.positive : AppColors.brandBlack).withValues(
              alpha: 0.3,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              on ? Icons.verified_user_rounded : Icons.gpp_maybe_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  on ? 'App Lock is on' : 'App Lock is off',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !on
                      ? 'Anyone with your phone can open Brixen'
                      : withBiometric
                      ? 'Protected by PIN and fingerprint'
                      : 'Protected by your PIN',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// White rounded card holding the tiles, with dividers between them.
class _Group extends StatelessWidget {
  final List<Widget> tiles;
  const _Group({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 66, color: AppColors.border),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
