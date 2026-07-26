import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          'App Lock',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          if (state.status == SecurityStatus.initial ||
              state.status == SecurityStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.silver),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SectionLabel('Lock Methods'),
              _SettingsTile(
                icon: Icons.pin_outlined,
                title: 'PIN Lock',
                subtitle: state.isPinEnabled
                    ? 'PIN lock is active'
                    : 'Set a 4-digit PIN',
                trailing: Switch.adaptive(
                  value: state.isPinEnabled,
                  activeThumbColor: AppColors.silver,
                  onChanged: (val) {
                    if (val) {
                      context.push(AppRouter.setPin);
                    } else {
                      context.read<SecurityCubit>().disablePin();
                    }
                  },
                ),
              ),
              if (state.isPinEnabled)
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Change PIN',
                  subtitle: 'Update your 4-digit PIN',
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () => context.push(AppRouter.setPin),
                ),
              if (state.isBiometricAvailable) ...[
                const SizedBox(height: 20),
                _SectionLabel('Biometric'),
                _SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Fingerprint Lock',
                  subtitle: state.isPinEnabled
                      ? 'Use fingerprint as an alternative to PIN'
                      : 'Enable PIN first to use fingerprint',
                  trailing: Switch.adaptive(
                    value: state.isBiometricEnabled,
                    activeThumbColor: AppColors.silver,
                    onChanged: state.isPinEnabled
                        ? (val) =>
                            context.read<SecurityCubit>().setBiometric(val)
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'When App Lock is enabled, you\'ll be asked to verify your identity each time you open the app.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.silver,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              decoration: BoxDecoration(
                color: AppColors.silver.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.silver, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
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
