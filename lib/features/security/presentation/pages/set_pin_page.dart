import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

enum _SetPinStep { verifyOld, enterNew, confirmNew }

class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  late _SetPinStep _step;
  late final bool _hasVerifyStep;
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // If a PIN is already set, require verifying it before allowing a change.
    _hasVerifyStep = context.read<SecurityCubit>().state.isPinEnabled;
    _step = _hasVerifyStep ? _SetPinStep.verifyOld : _SetPinStep.enterNew;
  }

  List<_SetPinStep> get _steps => _hasVerifyStep
      ? const [_SetPinStep.verifyOld, _SetPinStep.enterNew, _SetPinStep.confirmNew]
      : const [_SetPinStep.enterNew, _SetPinStep.confirmNew];

  // ── Verify old PIN ─────────────────────────────────────────────────────────

  Future<void> _onOldPinComplete() async {
    setState(() => _submitting = true);
    try {
      final ok = await context.read<SecurityCubit>().verifyPin(_oldPin);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _step = _SetPinStep.enterNew;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Incorrect PIN. Try again.';
          _oldPin = '';
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await TokenService.clear();
        await securityCubit.disablePin();
        if (mounted) context.go(AppRouter.signIn);
      } else {
        setState(() {
          _error = 'Unable to verify PIN. Try again.';
          _oldPin = '';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Set new PIN ─────────────────────────────────────────────────────────────

  void _onNewPinComplete() => setState(() {
        _step = _SetPinStep.confirmNew;
        _error = null;
      });

  Future<void> _onConfirmComplete() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
      });
      return;
    }
    final currentPin = _oldPin.isNotEmpty ? _oldPin : null;
    setState(() => _submitting = true);
    try {
      await context
          .read<SecurityCubit>()
          .enablePin(_newPin, currentPin: currentPin);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        // Access token invalid/expired — not a PIN rejection. Force re-login.
        await TokenService.clear();
        await securityCubit.disablePin();
        if (mounted) context.go(AppRouter.signIn);
        return;
      }
      setState(() {
        _step = _SetPinStep.verifyOld;
        _error = e.statusCode == 400
            ? 'Current PIN is incorrect. Try again.'
            : 'Could not update PIN. Try again.';
        _oldPin = '';
        _newPin = '';
        _confirmPin = '';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Back navigation ─────────────────────────────────────────────────────────

  void _onBack() {
    switch (_step) {
      case _SetPinStep.verifyOld:
        context.pop();
      case _SetPinStep.enterNew:
        if (_oldPin.isNotEmpty) {
          setState(() {
            _step = _SetPinStep.verifyOld;
            _newPin = '';
            _error = null;
          });
        } else {
          context.pop();
        }
      case _SetPinStep.confirmNew:
        setState(() {
          _step = _SetPinStep.enterNew;
          _confirmPin = '';
          _error = null;
        });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  String get _title => switch (_step) {
        _SetPinStep.verifyOld => 'Current PIN',
        _SetPinStep.enterNew => 'New PIN',
        _SetPinStep.confirmNew => 'Confirm PIN',
      };

  String get _subtitle => switch (_step) {
        _SetPinStep.verifyOld => 'Enter your current 6-digit PIN',
        _SetPinStep.enterNew => 'Choose a new 6-digit PIN',
        _SetPinStep.confirmNew => 'Re-enter your new PIN to confirm',
      };

  IconData get _stepIcon => switch (_step) {
        _SetPinStep.verifyOld => Icons.lock_outline_rounded,
        _SetPinStep.enterNew => Icons.vpn_key_outlined,
        _SetPinStep.confirmNew => Icons.check_circle_outline_rounded,
      };

  String get _currentPin => switch (_step) {
        _SetPinStep.verifyOld => _oldPin,
        _SetPinStep.enterNew => _newPin,
        _SetPinStep.confirmNew => _confirmPin,
      };

  ValueChanged<String> get _onChanged => (v) => setState(() {
        switch (_step) {
          case _SetPinStep.verifyOld:
            _oldPin = v;
          case _SetPinStep.enterNew:
            _newPin = v;
          case _SetPinStep.confirmNew:
            _confirmPin = v;
        }
        _error = null;
      });

  VoidCallback get _onSubmit => switch (_step) {
        _SetPinStep.verifyOld => _onOldPinComplete,
        _SetPinStep.enterNew => _onNewPinComplete,
        _SetPinStep.confirmNew => _onConfirmComplete,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, _) => Scaffold(
        backgroundColor:
            isDark ? AppColors.background : AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: cs.onSurface),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _StepProgress(steps: _steps, current: _step),
                      const SizedBox(height: 36),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isDark ? AppColors.silverGradient : null,
                          color: isDark ? null : AppColors.lightSurfaceElevated,
                          border: Border.all(color: AppColors.silver.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.silver.withValues(alpha: isDark ? 0.22 : 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(_stepIcon, size: 32, color: isDark ? AppColors.black : AppColors.silverDark),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _title,
                        style: TextStyle(color: cs.onSurface, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      PinPad(
                        pin: _currentPin,
                        maxLength: 6,
                        onChanged: _onChanged,
                        onSubmit: _onSubmit,
                        errorText: _error,
                        isLoading: _submitting,
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _StepProgress extends StatelessWidget {
  final List<_SetPinStep> steps;
  final _SetPinStep current;
  const _StepProgress({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    final index = steps.indexOf(current);
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= index;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: active ? AppColors.silver : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
