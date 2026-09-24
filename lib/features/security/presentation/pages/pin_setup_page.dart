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

enum _SetupStep { enterPin, confirmPin, biometric }

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  _SetupStep _step = _SetupStep.enterPin;
  String _pin = '';
  String _confirmPin = '';
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    securityCubit.load();
    // If PIN is already configured (returning user logged out + back in),
    // skip setup and go straight to the dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final alreadySet = await securityCubit.isLockActive();
      if (alreadySet && mounted) _goToDashboard();
    });
  }

  // Dashboard first, then a tapped push's target on top (if the app was
  // launched by one), so back from it returns to the dashboard.
  void _goToDashboard() {
    context.go(AppRouter.dashboard);
    final pushRoute = PushTokenService.takePendingRoute();
    if (pushRoute != null) context.push(pushRoute);
  }

  Future<void> _onPinEntered() async {
    setState(() {
      _step = _SetupStep.confirmPin;
      _confirmPin = '';
      _error = null;
    });
  }

  Future<void> _onConfirmEntered() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      await securityCubit.enablePin(_pin);
      if (!mounted) return;
      if (securityCubit.state.isBiometricAvailable) {
        setState(() => _step = _SetupStep.biometric);
      } else {
        _goToDashboard();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _SetupStep.enterPin;
        _pin = '';
        _confirmPin = '';
        _error = 'Could not set up PIN. Try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _enableBiometric() async {
    final ok = await securityCubit.authenticateWithBiometric();
    if (ok) await securityCubit.setBiometric(true);
    if (mounted) _goToDashboard();
  }

  void _skipBiometric() => _goToDashboard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.background : AppColors.lightBackground,
        body: Column(
          children: [
            if (_step != _SetupStep.biometric)
              SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goToDashboard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<SecurityCubit, SecurityState>(
                bloc: securityCubit,
                builder: (context, state) {
                  if (_step == _SetupStep.biometric) {
                    return _BiometricStep(
                      onEnable: _enableBiometric,
                      onSkip: _skipBiometric,
                    );
                  }
                  return _PinStep(
                    isConfirming: _step == _SetupStep.confirmPin,
                    pin: _step == _SetupStep.enterPin ? _pin : _confirmPin,
                    error: _error,
                    isLoading: _submitting,
                    onChanged: (v) => setState(() {
                      if (_step == _SetupStep.enterPin) {
                        _pin = v;
                      } else {
                        _confirmPin = v;
                      }
                      _error = null;
                    }),
                    onSubmit: _step == _SetupStep.enterPin
                        ? _onPinEntered
                        : _onConfirmEntered,
                    onBack: _step == _SetupStep.confirmPin
                        ? () => setState(() {
                              _step = _SetupStep.enterPin;
                              _confirmPin = '';
                              _error = null;
                            })
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinStep extends StatelessWidget {
  final bool isConfirming;
  final String pin;
  final String? error;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onBack;

  const _PinStep({
    required this.isConfirming,
    required this.pin,
    required this.error,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const BrandIllustration(deviceIcon: Icons.vpn_key_rounded),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Brix', style: TextStyle(color: AppColors.brand)),
                          const TextSpan(text: 'en', style: TextStyle(color: AppColors.positive)),
                        ]),
                        style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'Work smart. ', style: TextStyle(color: AppColors.ink)),
                          TextSpan(text: 'Grow together.', style: TextStyle(color: AppColors.positive.withValues(alpha: 0.9))),
                        ]),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isConfirming ? 'Confirm your PIN' : 'Create a 6-digit PIN',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConfirming
                            ? 'Re-enter your PIN to confirm'
                            : 'This PIN protects your app.\nYou\'ll need it each time you open Brixen.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppColors.shadows([
                            BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 30, offset: const Offset(0, 16)),
                            BoxShadow(color: AppColors.highlightShadow(0.9), blurRadius: 14, offset: const Offset(-8, -8)),
                          ]),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PinPad(
                              pin: pin,
                              maxLength: 6,
                              onChanged: onChanged,
                              onSubmit: onSubmit,
                              errorText: error,
                              isLoading: isLoading,
                            ),
                            if (isConfirming) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: isLoading ? null : onBack,
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BiometricStep extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const _BiometricStep({required this.onEnable, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
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
                size: 52,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Enable Fingerprint?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use your fingerprint as a faster\nalternative to your PIN',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 52),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEnable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Enable Fingerprint',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
