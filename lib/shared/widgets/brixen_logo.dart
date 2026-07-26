import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrixenLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const BrixenLogo({super.key, this.size = 130, this.animate = true});

  @override
  State<BrixenLogo> createState() => _BrixenLogoState();
}

class _BrixenLogoState extends State<BrixenLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<CurvedAnimation> _blockAnims;

  // [left, top, width, height] — fractions of inner square
  static const List<List<double>> _defs = [
    [0.00, 0.00, 0.60, 0.27], // top-left  wide
    [0.66, 0.00, 0.28, 0.27], // top-right small
    [0.00, 0.36, 0.28, 0.27], // mid-left  small
    [0.66, 0.36, 0.28, 0.27], // mid-right small
    [0.00, 0.72, 0.28, 0.27], // bot-left  small
    [0.34, 0.72, 0.60, 0.27], // bot-right wide (mirrored)
  ];

  // Direction each block flies in FROM (×inner)
  static const List<Offset> _origins = [
    Offset(-1.2, -1.2),
    Offset(1.2, -1.2),
    Offset(-1.2, 0.0),
    Offset(1.2, 0.0),
    Offset(-1.2, 1.2),
    Offset(1.2, 1.2),
  ];

  static const List<double> _starts = [0.00, 0.06, 0.11, 0.11, 0.17, 0.22];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _blockAnims = List.generate(6, (i) {
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          _starts[i],
          (_starts[i] + 0.60).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    for (final a in _blockAnims) {
      a.dispose();
    }
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final inner = s * 0.68;
    final radius = (inner * 0.05).clamp(2.0, 8.0);

    return SizedBox(
      width: s,
      height: s,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.rotate(
              angle: math.pi / 4,
              child: SizedBox(
                width: inner,
                height: inner,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: List.generate(6, (i) {
                    final d = _defs[i];
                    final o = _origins[i];
                    final t = _blockAnims[i].value.clamp(0.0, 1.0);

                    return Positioned(
                      left: d[0] * inner + o.dx * inner * (1 - t),
                      top: d[1] * inner + o.dy * inner * (1 - t),
                      width: d[2] * inner,
                      height: d[3] * inner,
                      child: Opacity(
                        opacity: t,
                        child: _SilverBlock(radius: radius),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SilverBlock extends StatelessWidget {
  final double radius;
  const _SilverBlock({required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.silverGradient : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF111111),
            Color(0xFF1C1C1C),
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
