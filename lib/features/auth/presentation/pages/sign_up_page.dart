import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _companyCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            companyCode: _companyCodeController.text.trim().toUpperCase(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // TODO: context.go(AppRouter.dashboard);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.dangerFill,
              ),
            );
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: -80, right: -80, child: _Orb(size: 240)),

              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: cs.primary,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.createAccount,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.signUpSubtitle,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 36),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          BrixenTextField(
                            label: AppStrings.fullName,
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Full name is required';
                              if (v.trim().length < 2) return 'Name is too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          BrixenTextField(
                            label: AppStrings.companyCode,
                            hint: 'e.g. ACME2024',
                            controller: _companyCodeController,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.business_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Company code is required';
                              if (v.trim().length < 3) return 'Invalid company code';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          BrixenTextField(
                            label: AppStrings.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          BrixenTextField(
                            label: AppStrings.password,
                            controller: _passwordController,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 8) return 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          BrixenTextField(
                            label: AppStrings.confirmPassword,
                            controller: _confirmPasswordController,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) => BrixenButton(
                              label: AppStrings.signUp,
                              isLoading: state is AuthLoading,
                              onPressed: _submit,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.alreadyHaveAccount,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Text(
                                  AppStrings.signIn,
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () => themeCubit.toggle(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  const _Orb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.silver.withValues(alpha: 0.07),
            AppColors.silver.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
