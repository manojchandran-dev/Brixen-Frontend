import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../../data/pin_remote_datasource.dart';
import '../cubit/security_cubit.dart';
import 'set_pin_page.dart';

/// Forgot PIN from the lock screen: email OTP → verify → new PIN → confirm.
/// Resolves true once the new PIN is set (the user is signed in fresh).
Future<bool> showForgotPinSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: securityCubit,
        child: const ForgotPinSheet(),
      ),
    ) ??
    false;

enum _Step { send, code, newPin, confirm }

class ForgotPinSheet extends StatefulWidget {
  const ForgotPinSheet({super.key});

  @override
  State<ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends State<ForgotPinSheet> {
  _Step _step = _Step.send;
  String _email = '';
  String _resetToken = '';
  String _code = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _error;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Runs [action] with the spinner on; a 401 means the saved session is
  /// gone, so the only way back in is signing in with the password.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await TokenService.clear();
        await securityCubit.disablePin();
        if (!mounted) return;
        Navigator.of(context).pop(false);
        context.go(AppRouter.signIn);
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    final email = await pinRemoteDatasource.forgotPin();
    if (!mounted) return;
    setState(() {
      _email = email.isNotEmpty ? email : (TokenService.email ?? 'your email');
      _code = '';
      _resetToken = '';
      _step = _Step.code;
    });
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendIn <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  });

  Future<void> _verify() => _run(() async {
    try {
      _resetToken = await pinRemoteDatasource.verifyForgotPinOtp(_code);
    } finally {
      // Wrong code: clear it for another try (the error shows under it).
      if (mounted && _resetToken.isEmpty) setState(() => _code = '');
    }
    if (mounted) setState(() => _step = _Step.newPin);
  });

  Future<void> _confirm() async {
    if (_confirmPin != _newPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
      });
      return;
    }
    await _run(() async {
      await context.read<SecurityCubit>().resetForgottenPin(
        _resetToken,
        _newPin,
      );
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  void _back() {
    setState(() {
      _error = null;
      switch (_step) {
        case _Step.send:
          Navigator.of(context).pop(false);
        case _Step.code:
          _step = _Step.send;
        case _Step.newPin:
          // The reset token is still good; no need to re-verify.
          Navigator.of(context).pop(false);
        case _Step.confirm:
          _confirmPin = '';
          _step = _Step.newPin;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon) = switch (_step) {
      _Step.send => (
        'Forgot PIN?',
        "We'll email a 6-digit code to confirm it's you, then you can set a new PIN.",
        Icons.lock_reset_rounded,
      ),
      _Step.code => (
        'Check your email',
        'Enter the 6-digit code sent to\n$_email',
        Icons.mark_email_read_outlined,
      ),
      _Step.newPin => (
        'New PIN',
        'Choose a new 6-digit PIN',
        Icons.vpn_key_outlined,
      ),
      _Step.confirm => (
        'Confirm PIN',
        'Re-enter your new PIN to confirm',
        Icons.check_circle_outline_rounded,
      ),
    };
    final (pin, onChanged, onSubmit) = switch (_step) {
      _Step.send => ('', null, null),
      _Step.code => (_code, (String v) => _code = v, _verify),
      _Step.newPin => (
        _newPin,
        (String v) => _newPin = v,
        () => setState(() => _step = _Step.confirm),
      ),
      _Step.confirm => (_confirmPin, (String v) => _confirmPin = v, _confirm),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _busy ? null : _back,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  PinStepper(
                    labels: const ['Email', 'Code', 'New', 'Confirm'],
                    current: _step.index,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 30, color: AppColors.brand),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_step == _Step.send) ...[
                    if (_error != null) ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    BrixenButton(
                      label: 'Send code',
                      isLoading: _busy,
                      onPressed: _busy ? null : _send,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    PinPad(
                      // A fresh pad per step, so the eye starts hidden.
                      key: ValueKey(_step),
                      pin: pin,
                      maxLength: 6,
                      onChanged: (v) => setState(() {
                        onChanged!(v);
                        _error = null;
                      }),
                      onSubmit: onSubmit,
                      errorText: _error,
                      isLoading: _busy,
                    ),
                    if (_step == _Step.code)
                      TextButton(
                        onPressed: _resendIn > 0 || _busy ? null : _send,
                        child: Text(
                          _resendIn > 0
                              ? 'Resend code in ${_resendIn}s'
                              : 'Resend code',
                          style: TextStyle(
                            color: _resendIn > 0
                                ? AppColors.textHint
                                : AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
