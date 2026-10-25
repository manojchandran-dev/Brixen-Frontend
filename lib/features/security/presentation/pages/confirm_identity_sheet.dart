import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../cubit/security_cubit.dart';

/// "Confirm it's you" before a sensitive action such as switching accounts:
/// the fingerprint first when it's turned on, else (or if it's cancelled)
/// this device's PIN. With no PIN set on the device there's nothing to
/// check, so it passes. Returns whether the user confirmed.
Future<bool> confirmIdentity(
  BuildContext context, {
  String reason = 'Confirm it\'s you to switch accounts',
}) async {
  if (!await securityCubit.isLockActive()) return true;
  await securityCubit.load();
  final s = securityCubit.state;
  if (s.isBiometricEnabled && s.isBiometricAvailable) {
    if (await securityCubit.authenticateWithBiometric()) return true;
  }
  if (!context.mounted) return false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConfirmIdentitySheet(reason: reason),
  );
  return ok == true;
}

class _ConfirmIdentitySheet extends StatefulWidget {
  final String reason;
  const _ConfirmIdentitySheet({required this.reason});

  @override
  State<_ConfirmIdentitySheet> createState() => _ConfirmIdentitySheetState();
}

class _ConfirmIdentitySheetState extends State<_ConfirmIdentitySheet> {
  String _pin = '';
  String? _error;
  bool _checking = false;

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await securityCubit.checkLocalPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _pin = '';
        _error = 'Incorrect PIN. Try again.';
      });
    }
  }

  Future<void> _fingerprint() async {
    if (await securityCubit.authenticateWithBiometric() && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = securityCubit.state;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Confirm it\'s you',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.reason,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              PinPad(
                pin: _pin,
                maxLength: 6,
                onChanged: (v) => setState(() {
                  _pin = v;
                  _error = null;
                }),
                onSubmit: _submit,
                errorText: _error,
                isLoading: _checking,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  if (s.isBiometricEnabled && s.isBiometricAvailable) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _fingerprint,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use fingerprint'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
