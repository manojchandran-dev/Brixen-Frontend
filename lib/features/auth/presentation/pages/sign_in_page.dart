import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/brixen_logo.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            switch (state.role) {
              case UserRole.superAdmin:
                context.go(AppRouter.companies);
              case UserRole.companyAdmin:
                context.go(AppRouter.companyAdminHome);
              case UserRole.employee:
                context.go(AppRouter.employeeHome);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative orbs
              Positioned(top: -80, right: -80, child: _Orb(size: 240)),
              Positioned(bottom: -100, left: -50, child: _Orb(size: 180)),

              // Main scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64),
                    BrixenLogo(size: 72, animate: false),
                    const SizedBox(height: 40),
                    Text(
                      AppStrings.welcomeBack,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.signInSubtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrixenTextField(
                            label: AppStrings.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            // validator: (v) {
                            //   if (v == null || v.isEmpty) return 'Email is required';
                            //   if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            //     return 'Enter a valid email';
                            //   }
                            //   return null;
                            // },
                          ),
                          const SizedBox(height: 16),
                          BrixenTextField(
                            label: AppStrings.password,
                            controller: _passwordController,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            // validator: (v) {
                            //   if (v == null || v.isEmpty) return 'Password is required';
                            //   if (v.length < 6) return 'Minimum 6 characters';
                            //   return null;
                            // },
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) => BrixenButton(
                              label: AppStrings.signIn,
                              isLoading: state is AuthLoading,
                              onPressed: _submit,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant, fontSize: 11),
                                ),
                              ),
                              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.dontHaveAccount,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRouter.signUp),
                                child: Text(
                                  AppStrings.createAccount,
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle sits last → renders on top → receives taps
              Positioned(
                top: 12,
                right: 20,
                child: _ThemeToggle(),
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


