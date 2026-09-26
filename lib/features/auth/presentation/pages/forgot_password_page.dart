import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brand_illustration.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../data/datasources/password_reset_remote_datasource.dart';

enum _ForgotStep { email, otp, newPassword, success }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  _ForgotStep _step = _ForgotStep.email;
  bool _submitting = false;
  String? _error;

  // Step 1 — email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  // Step 2 — OTP
  static const _otpLength = 6;
  late final List<TextEditingController> _otpCtrls = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _otpFocus = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  Timer? _resendTimer;
  int _resendSeconds = 0;

  // Step 3 — new password
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _resetToken;

  String get _otp => _otpCtrls.map((c) => c.text).join();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Step 1: send OTP ───────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await passwordResetRemoteDatasource.sendOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = _ForgotStep.otp;
      });
      _startResendCooldown();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _otpFocus.first.requestFocus(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    for (final c in _otpCtrls) {
      c.clear();
    }
    setState(() => _error = null);
    try {
      await passwordResetRemoteDatasource.sendOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      _startResendCooldown();
      _otpFocus.first.requestFocus();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // ── Step 2: verify OTP ─────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otp.length < _otpLength) {
      setState(() => _error = 'Enter the full $_otpLength-digit code');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = await passwordResetRemoteDatasource.verifyOtp(
        email: _emailCtrl.text.trim(),
        otp: _otp,
      );
      if (!mounted) return;
      _resetToken = token;
      setState(() {
        _submitting = false;
        _step = _ForgotStep.newPassword;
      });
      _resendTimer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  // ── Step 3: set new password ───────────────────────────────────────────────

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await passwordResetRemoteDatasource.resetPassword(
        resetToken: _resetToken!,
        newPassword: _newPasswordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = _ForgotStep.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  // ── Back navigation ───────────────────────────────────────────────────────

  void _onBack() {
    switch (_step) {
      case _ForgotStep.email:
        context.pop();
      case _ForgotStep.otp:
        _resendTimer?.cancel();
        setState(() {
          _step = _ForgotStep.email;
          _error = null;
        });
      case _ForgotStep.newPassword:
        setState(() {
          _step = _ForgotStep.otp;
          _error = null;
        });
      case _ForgotStep.success:
        context.pop();
    }
  }

  // ── Copy per step ─────────────────────────────────────────────────────────

  String get _titleLead => switch (_step) {
    _ForgotStep.email => 'Forgot',
    _ForgotStep.otp => 'Verify Your',
    _ForgotStep.newPassword => 'Set New',
    _ForgotStep.success => 'Password',
  };

  String get _titleAccent => switch (_step) {
    _ForgotStep.email => 'Password?',
    _ForgotStep.otp => 'Email',
    _ForgotStep.newPassword => 'Password',
    _ForgotStep.success => 'Reset',
  };

  String get _subtitle => switch (_step) {
    _ForgotStep.email =>
      'Enter the email associated with your account\nand we\'ll send you a verification code.',
    _ForgotStep.otp =>
      'Enter the $_otpLength-digit code sent to\n${_emailCtrl.text.trim()}',
    _ForgotStep.newPassword => 'Choose a new password for your account.',
    _ForgotStep.success =>
      'Your password has been reset successfully.\nYou can now sign in with your new password.',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_step != _ForgotStep.success) ...[
                Center(
                  child: BrandIllustration(
                    deviceIcon: Icons.restart_alt_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text.rich(
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
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text.rich(
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_titleLead ',
                                  style: TextStyle(color: AppColors.ink),
                                ),
                                TextSpan(
                                  text: _titleAccent,
                                  style: const TextStyle(
                                    color: AppColors.positive,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [AppColors.brand, AppColors.positive],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topLeft,
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 28),
                    _buildStep(cs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ColorScheme cs) {
    switch (_step) {
      case _ForgotStep.email:
        return Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrixenTextField(
                label: 'Email address',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sendOtp(),
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              BrixenButton(
                label: 'Send OTP',
                isLoading: _submitting,
                onPressed: _submitting ? null : _sendOtp,
              ),
            ],
          ),
        );

      case _ForgotStep.otp:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OtpInput(
              controllers: _otpCtrls,
              focusNodes: _otpFocus,
              length: _otpLength,
              hasError: _error != null,
              onCompleted: _verifyOtp,
            ),
            const SizedBox(height: 24),
            BrixenButton(
              label: 'Verify OTP',
              isLoading: _submitting,
              onPressed: _submitting ? null : _verifyOtp,
            ),
            const SizedBox(height: 20),
            Center(
              child: _resendSeconds > 0
                  ? Text(
                      'Resend code in ${_resendSeconds}s',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    )
                  : GestureDetector(
                      onTap: _resendOtp,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppColors.brand,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        );

      case _ForgotStep.newPassword:
        return Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrixenTextField(
                label: 'New password',
                controller: _newPasswordCtrl,
                isPassword: true,
                iconColor: AppColors.positive,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              BrixenTextField(
                label: 'Confirm password',
                controller: _confirmPasswordCtrl,
                isPassword: true,
                iconColor: AppColors.positive,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _resetPassword(),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _newPasswordCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              BrixenButton(
                label: 'Reset Password',
                isLoading: _submitting,
                onPressed: _submitting ? null : _resetPassword,
              ),
            ],
          ),
        );

      case _ForgotStep.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.positive.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.positive.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.positive,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            BrixenButton(
              label: 'Back to Sign In',
              onPressed: () => context.pop(),
            ),
          ],
        );
    }
  }
}

// (input field + button now come from shared/widgets/brixen_text_field.dart
// and shared/widgets/brixen_button.dart)

// ── OTP input ────────────────────────────────────────────────────────────────

class _OtpInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int length;
  final bool hasError;
  final VoidCallback onCompleted;

  const _OtpInput({
    required this.controllers,
    required this.focusNodes,
    required this.length,
    required this.hasError,
    required this.onCompleted,
  });

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < length - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (controllers.every((c) => c.text.isNotEmpty)) {
      focusNodes[index].unfocus();
      onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  controllers[i].text.isEmpty &&
                  i > 0) {
                focusNodes[i - 1].requestFocus();
                controllers[i - 1].clear();
              }
            },
            child: TextField(
              controller: controllers[i],
              focusNode: focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? AppColors.error : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? AppColors.error : AppColors.border,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.brand, width: 1.5),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}
