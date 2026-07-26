import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_logo.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final cubit = context.read<SecurityCubit>();
    if (!cubit.state.isBiometricEnabled) return;
    final ok = await cubit.authenticateWithBiometric();
    if (ok && mounted) context.go(AppRouter.companies);
  }

  void _onPinChanged(String v) => setState(() {
        _pin = v;
        _error = null;
      });

  Future<void> _onPinComplete() async {
    final ok = await context.read<SecurityCubit>().verifyPin(_pin);
    if (ok) {
      if (mounted) context.go(AppRouter.companies);
    } else {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  const BrixenLogo(size: 72, animate: false),
                  const SizedBox(height: 16),
                  Text(
                    'BRIXEN',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN to continue',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 48),
                  PinPad(
                    pin: _pin,
                    onChanged: _onPinChanged,
                    onSubmit: _onPinComplete,
                    errorText: _error,
                  ),
                  if (state.isBiometricEnabled) ...[
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _tryBiometric,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.silver.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              color: AppColors.silver,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use Fingerprint',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
