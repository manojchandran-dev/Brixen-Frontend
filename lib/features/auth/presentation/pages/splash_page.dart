import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../shared/widgets/brixen_logo.dart';
import '../../../security/presentation/cubit/security_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
    _scaleAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack);
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 3400));
    if (!mounted) return;
    if (TokenService.isLoggedIn) {
      final pinEnabled = await securityCubit.isLockActive();
      if (!mounted) return;
      if (pinEnabled) {
        context.go(AppRouter.lockScreen);
      } else {
        context.go(AppRouter.pinSetup);
      }
    } else {
      context.go(AppRouter.signIn);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: _Orb(size: 300, color: AppColors.brand)),
          Positioned(bottom: -120, left: -60, child: _Orb(size: 240, color: AppColors.positive)),

          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing brand-colour glow behind the assembling mark
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            final pulse = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
                            return Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color.lerp(AppColors.brand, AppColors.positive, pulse)!.withValues(alpha: 0.16),
                                    Color.lerp(AppColors.brand, AppColors.positive, pulse)!.withValues(alpha: 0.03),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const BrixenLogo(size: 140, animate: true),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Brix', style: TextStyle(color: AppColors.brand)),
                        const TextSpan(text: 'en', style: TextStyle(color: AppColors.positive)),
                      ]),
                      style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),

                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Work smart. ', style: TextStyle(color: AppColors.ink)),
                        TextSpan(text: 'Grow together.', style: TextStyle(color: AppColors.positive.withValues(alpha: 0.9))),
                      ]),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
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
                  width: 120,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
