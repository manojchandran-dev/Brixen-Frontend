import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brand_illustration.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authCubit,
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
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(state.hasPin ? AppRouter.lockScreen : AppRouter.pinSetup);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.dangerFill),
            );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandIllustration(deviceIcon: Icons.login_rounded),
                        const SizedBox(height: 18),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Brix', style: TextStyle(color: AppColors.brand)),
                            const TextSpan(text: 'en', style: TextStyle(color: AppColors.positive)),
                          ]),
                          style: GoogleFonts.spaceGrotesk(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -1),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Work smart. ', style: TextStyle(color: AppColors.ink)),
                            TextSpan(text: 'Grow together.', style: TextStyle(color: AppColors.positive.withValues(alpha: 0.9))),
                          ]),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        _AuthCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onSubmit: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Sign-in card ─────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _AuthCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.shadows([
          BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 30, offset: const Offset(0, 16)),
          BoxShadow(color: AppColors.highlightShadow(0.9), blurRadius: 14, offset: const Offset(-8, -8)),
        ]),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Welcome ', style: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w800)),
              const Text('back', style: TextStyle(color: AppColors.positive, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 6),
            Text('Sign in to continue to your account',
                style: TextStyle(color: AppColors.ink, fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(colors: [AppColors.brand, AppColors.positive]),
              ),
            ),
            const SizedBox(height: 26),

            _AuthField(
              icon: Icons.mail_outline_rounded,
              hint: 'Email address',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              icon: Icons.lock_outline_rounded,
              iconBoxColor: AppColors.positive,
              hint: 'Password',
              controller: passwordController,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              suffix: GestureDetector(
                onTap: onToggleObscure,
                child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textHint),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(AppRouter.forgotPassword),
                child: const Text('Forgot password?', style: TextStyle(color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 22),

            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) => _SignInButton(isLoading: state is AuthLoading, onPressed: onSubmit),
            ),
          ],
          ),
        ),
    );
  }
}

// ── Icon-box + pill input field ─────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final IconData icon;
  final Color iconBoxColor;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _AuthField({
    required this.icon,
    this.iconBoxColor = AppColors.brand,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: TextStyle(color: AppColors.ink, fontSize: 14),
        decoration: InputDecoration(
          isDense: false,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 10),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [iconBoxColor, iconBoxColor.withValues(alpha: 0.75)],
                ),
                boxShadow: AppColors.shadows([
                  BoxShadow(color: iconBoxColor.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 3)),
                ]),
              ),
              child: Icon(icon, color: AppColors.white, size: 17),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 14), child: suffix),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        ),
      ),
    );
  }
}

// ── Sign in button ───────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(colors: [AppColors.brand, AppColors.positive], begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))]),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Sign in', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

