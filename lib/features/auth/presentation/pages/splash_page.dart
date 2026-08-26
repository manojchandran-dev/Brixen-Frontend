import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/token_service.dart';
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
    _scaleAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    );
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
          Positioned(
            top: -100,
            right: -80,
            child: _Orb(size: 300, color: AppColors.brand),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: _Orb(size: 240, color: AppColors.positive),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing brand-colour glow behind the bar-chart mark
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            final pulse =
                                (math.sin(_glowController.value * 2 * math.pi) +
                                    1) /
                                2;
                            return Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color.lerp(
                                      AppColors.brand,
                                      AppColors.positive,
                                      pulse,
                                    )!.withValues(alpha: 0.16),
                                    Color.lerp(
                                      AppColors.brand,
                                      AppColors.positive,
                                      pulse,
                                    )!.withValues(alpha: 0.03),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const _BarLogoMark(size: 140),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text.rich(
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text.rich(
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.brand,
                        ),
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

/// The Brixen mark, redrawn as real animated geometry instead of a static
/// image — three bars rise (bottom-up, staggered, with a bounce), each with
/// its own 3D bevel + drop shadow, then a trend line draws itself across
/// their tops and a node circle pops in at each vertex.
class _BarLogoMark extends StatefulWidget {
  final double size;
  const _BarLogoMark({required this.size});

  @override
  State<_BarLogoMark> createState() => _BarLogoMarkState();
}

class _BarLogoMarkState extends State<_BarLogoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _barGrow;
  late final Animation<double> _lineProgress;
  late final List<Animation<double>> _nodePop;

  // [x, barWidth, topFraction (0 = tallest reach, 1 = baseline), color]
  static const _bars = [
    (dx: 0.0, w: 0.20, topFrac: 0.68),
    (dx: 0.29, w: 0.20, topFrac: 0.40),
    (dx: 0.58, w: 0.22, topFrac: 0.12),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _barGrow = List.generate(3, (i) {
      final start = i * 0.14;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          start,
          (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.elasticOut,
        ),
      );
    });
    _lineProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _nodePop = List.generate(3, (i) {
      final start = 0.6 + i * 0.1;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          start.clamp(0.0, 1.0),
          (start + 0.15).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final baseline = s * 0.86;
    final maxBarTop = s * 0.30; // topFrac 0 lands here (tallest bar)

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            children: [
              for (int i = 0; i < _bars.length; i++)
                Builder(
                  builder: (context) {
                    final spec = _bars[i];
                    final targetTop =
                        maxBarTop + (baseline - maxBarTop) * spec.topFrac;
                    final grow = _barGrow[i].value.clamp(0.0, 1.0);
                    final top = baseline - (baseline - targetTop) * grow;
                    final color = i == 0
                        ? AppColors.brandBlack
                        : (i == 1 ? AppColors.positive : AppColors.brand);
                    return Positioned(
                      left: spec.dx * s,
                      top: top,
                      width: spec.w * s,
                      height: (baseline - top).clamp(0.0, s),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, 0.35)!,
                              color,
                              Color.lerp(color, Colors.black, 0.25)!,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(s * 0.045),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              CustomPaint(
                size: Size(s, s),
                painter: _TrendLinePainter(
                  points: [
                    for (final spec in _bars)
                      Offset(
                        spec.dx * s + spec.w * s / 2,
                        maxBarTop +
                            (baseline - maxBarTop) * spec.topFrac -
                            s * 0.10,
                      ),
                  ],
                  lineProgress: _lineProgress.value,
                  nodeScales: _nodePop.map((a) => a.value).toList(),
                  nodeRadius: s * 0.045,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<Offset> points;
  final double lineProgress;
  final List<double> nodeScales;
  final double nodeRadius;
  const _TrendLinePainter({
    required this.points,
    required this.lineProgress,
    required this.nodeScales,
    required this.nodeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineProgress <= 0) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final metric = path.computeMetrics().first;
    final revealed = metric.extractPath(
      0,
      metric.length * lineProgress.clamp(0.0, 1.0),
    );

    canvas.drawPath(
      revealed,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (int i = 0; i < points.length; i++) {
      final scale = i < nodeScales.length ? nodeScales[i].clamp(0.0, 1.0) : 0.0;
      if (scale <= 0) continue;
      final r = nodeRadius * scale;
      canvas.drawCircle(points[i], r, Paint()..color = AppColors.white);
      canvas.drawCircle(
        points[i],
        r * 0.55,
        Paint()..color = AppColors.brandDeep,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.lineProgress != lineProgress ||
      oldDelegate.nodeScales != nodeScales ||
      oldDelegate.points != points;
}
