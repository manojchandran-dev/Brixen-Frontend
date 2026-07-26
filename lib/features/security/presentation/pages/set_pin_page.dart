import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../cubit/security_cubit.dart';

class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String? _error;

  void _onPinChanged(String v) => setState(() {
        _pin = v;
        _error = null;
      });

  void _onConfirmChanged(String v) => setState(() {
        _confirmPin = v;
        _error = null;
      });

  void _onPinComplete() => setState(() => _confirming = true);

  Future<void> _onConfirmComplete() async {
    if (_pin == _confirmPin) {
      await context.read<SecurityCubit>().enablePin(_pin);
      if (mounted) context.pop();
    } else {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () {
            if (_confirming) {
              setState(() {
                _confirming = false;
                _confirmPin = '';
                _error = null;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _confirming ? 'Confirm PIN' : 'Set PIN',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                _confirming
                    ? 'Re-enter your 4-digit PIN to confirm'
                    : 'Choose a 4-digit PIN for app lock',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PinPad(
                pin: _confirming ? _confirmPin : _pin,
                onChanged: _confirming ? _onConfirmChanged : _onPinChanged,
                onSubmit: _confirming ? _onConfirmComplete : _onPinComplete,
                errorText: _error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
