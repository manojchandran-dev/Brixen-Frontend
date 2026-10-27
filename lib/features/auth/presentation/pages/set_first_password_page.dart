import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// First sign-in with the temporary password from the setup email: choose
/// your own before using the app. Saving signs in with it, and the sign-in
/// page takes over from there (PIN, then the app). Back = sign in later.
class SetFirstPasswordPage extends StatefulWidget {
  final String email;
  const SetFirstPasswordPage({super.key, required this.email});

  @override
  State<SetFirstPasswordPage> createState() => _SetFirstPasswordPageState();
}

class _SetFirstPasswordPageState extends State<SetFirstPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().setFirstPassword(_password.text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      // Signed in with the new password: the sign-in page navigates on.
      listener: (context, state) {
        if (state is AuthAuthenticated && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (state is AuthError) setState(() => _error = state.message);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Set your password')),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Icon(
                  Icons.lock_reset_rounded,
                  size: 56,
                  color: AppColors.brand,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose your own password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You signed in as ${widget.email} with a temporary password. '
                  'Set a new one to continue — the temporary password stops '
                  'working.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                BrixenTextField(
                  label: 'New password *',
                  hint: 'At least 8 characters',
                  controller: _password,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  validator: (v) {
                    if ((v ?? '').length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                BrixenTextField(
                  label: 'Confirm new password *',
                  hint: 'Type it again',
                  controller: _confirm,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  validator: (v) =>
                      v != _password.text ? "Passwords don't match" : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.dangerFill),
                  ),
                ],
                const SizedBox(height: 24),
                BrixenButton(
                  label: 'Save and continue',
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
