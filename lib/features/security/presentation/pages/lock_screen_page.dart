import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/push_token_service.dart';
import '../../../../shared/widgets/brand_illustration.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';
import 'forgot_pin_sheet.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  String _pin = '';
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  // Dashboard first, then a tapped push's target on top (if the app was
  // launched by one), so back from it returns to the dashboard.
  void _goToDashboard() {
    context.go(AppRouter.dashboard);
    final pushRoute = PushTokenService.takePendingRoute();
    if (pushRoute != null) context.push(pushRoute);
  }

  Future<void> _tryBiometric() async {
    final cubit = context.read<SecurityCubit>();
    if (!cubit.state.isBiometricEnabled) return;
    final ok = await cubit.authenticateWithBiometric();
    if (ok && mounted) _goToDashboard();
  }

  void _onPinChanged(String v) => setState(() {
    _pin = v;
    _error = null;
  });

  Future<void> _onPinComplete() async {
    setState(() => _submitting = true);
    final ok = await context.read<SecurityCubit>().verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      _goToDashboard();
    } else {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _pin = '';
        _submitting = false;
      });
    }
  }

  Future<void> _forgotPin() async {
    final reset = await showForgotPinSheet(context);
    if (reset && mounted) _goToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : AppColors.lightBackground,
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth - 48,
                        child: _LockScreenContent(
                          pin: _pin,
                          error: _error,
                          submitting: _submitting,
                          isBiometricEnabled: state.isBiometricEnabled,
                          onPinChanged: _onPinChanged,
                          onPinComplete: _onPinComplete,
                          onBiometricTap: _tryBiometric,
                          onForgotPin: _forgotPin,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LockScreenContent extends StatelessWidget {
  final String pin;
  final String? error;
  final bool submitting;
  final bool isBiometricEnabled;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onPinComplete;
  final VoidCallback onBiometricTap;
  final VoidCallback onForgotPin;

  const _LockScreenContent({
    required this.pin,
    required this.error,
    required this.submitting,
    required this.isBiometricEnabled,
    required this.onPinChanged,
    required this.onPinComplete,
    required this.onBiometricTap,
    required this.onForgotPin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const BrandIllustration(deviceIcon: Icons.pin_rounded),
        const SizedBox(height: 18),
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
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Work smart. ',
                style: TextStyle(color: AppColors.ink),
              ),
              TextSpan(
                text: 'Grow together.',
                style: TextStyle(
                  color: AppColors.positive.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        Text(
          'Enter your PIN to continue',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.highlightShadow(0.9),
                blurRadius: 14,
                offset: const Offset(-8, -8),
              ),
            ]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PinPad(
                pin: pin,
                maxLength: 6,
                onChanged: onPinChanged,
                onSubmit: onPinComplete,
                errorText: error,
                isLoading: submitting,
              ),
              TextButton(
                onPressed: submitting ? null : onForgotPin,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: AppColors.brand,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isBiometricEnabled) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onBiometricTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.positive.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.positive.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          color: AppColors.positive,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use Fingerprint',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
