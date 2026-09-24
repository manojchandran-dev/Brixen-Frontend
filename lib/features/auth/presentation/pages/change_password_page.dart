import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/page_header_bar.dart';
import '../../data/datasources/change_password_remote_datasource.dart';

/// This page is always reached via `context.push` from More — tapping the
/// bottom nav's own "More" icon should just pop back to that existing page
/// instead of `context.go`-ing to a brand new one (which tears down and
/// rebuilds the whole route stack). Dashboard/Report aren't a "back"
/// relationship here, so those still go normally.
void _onNavTap(BuildContext context, int index) {
  if (index == 3) {
    context.pop();
    return;
  }
  context.go(index == 2 ? AppRouter.report : AppRouter.dashboard);
}

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(changePasswordRemoteDatasourceProvider)
          .changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.positive,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException
            ? e.message
            : 'Could not change password. Try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activeIndex: 3,
      onNavTap: (i) => _onNavTap(context, i),
      body: Column(
        children: [
          PageHeaderBar(title: 'Change Password'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrixenTextField(
                      label: 'Current password',
                      controller: _currentCtrl,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Current password is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    BrixenTextField(
                      label: 'New password',
                      controller: _newCtrl,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'New password is required';
                        }
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    BrixenTextField(
                      label: 'Confirm new password',
                      controller: _confirmCtrl,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (v != _newCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topLeft,
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
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
                    BrixenButton(
                      label: 'Update Password',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
