import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_logo.dart';
import '../../../security/presentation/cubit/security_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 3400));
    if (!mounted) return;
    final locked = await securityCubit.isLockActive();
    if (mounted) context.go(locked ? AppRouter.lockScreen : AppRouter.signIn);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradient
              : AppColors.lightBackgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(top: -100, right: -80, child: _Orb(size: 300)),
            Positioned(bottom: -120, left: -60, child: _Orb(size: 240)),

            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated assembled logo with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.silver.withValues(alpha: 0.15),
                                AppColors.silver.withValues(alpha: 0.03),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const BrixenLogo(size: 140, animate: true),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _PulseText(
                      text: AppStrings.appName,
                      shimmer: _shimmerController,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SizedBox(
                    width: 100,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) => LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.silver),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseText extends StatelessWidget {
  final String text;
  final AnimationController shimmer;
  final TextStyle style;

  const _PulseText({
    required this.text,
    required this.shimmer,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, child) {
        final pulse = (math.sin(shimmer.value * 2 * math.pi) + 1) / 2;
        final color = Color.lerp(AppColors.silver, AppColors.white, pulse)!;
        return Text(text, style: style.copyWith(color: color));
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
            AppColors.silver.withValues(alpha: 0.06),
            AppColors.silver.withValues(alpha: 0.01),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
