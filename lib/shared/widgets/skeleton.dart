import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Wraps any skeleton layout in a single continuous shimmer sweep — one
/// shared AnimationController driving every placeholder underneath it, so
/// a whole screen's skeleton highlights together instead of each box
/// animating independently.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - t * 3, 0),
              end: Alignment(1 - t * 3, 0),
              colors: [
                AppColors.ink.withValues(alpha: 0.05),
                AppColors.white.withValues(alpha: 0.9),
                AppColors.ink.withValues(alpha: 0.05),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded placeholder block — the atom every skeleton layout is
/// built from.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Mimics the shared list-card layout used across every module (icon badge
/// + title/subtitle + trailing chip, a stat row, a footer line) so list
/// pages don't jump in size once real content replaces the skeleton.
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadows([
          BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6)),
          BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SkeletonBox(width: 38, height: 38, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 130, height: 13, radius: 4),
                  SizedBox(height: 7),
                  SkeletonBox(width: 84, height: 10, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const SkeletonBox(width: 54, height: 20, radius: 10),
          ]),
          const SizedBox(height: 16),
          const SkeletonBox(height: 1, radius: 0),
          const SizedBox(height: 14),
          Row(children: const [
            Expanded(child: SkeletonBox(height: 10, radius: 4)),
            SizedBox(width: 18),
            Expanded(child: SkeletonBox(height: 10, radius: 4)),
            SizedBox(width: 18),
            Expanded(child: SkeletonBox(height: 10, radius: 4)),
          ]),
          const SizedBox(height: 14),
          const SkeletonBox(height: 1, radius: 0),
          const SizedBox(height: 12),
          const SkeletonBox(width: 100, height: 10, radius: 4),
        ],
      ),
    );
  }
}

/// Mimics a single [AppDrawer] menu row (icon badge + title/subtitle,
/// chevron) so the drawer doesn't jump in size once the real menu loads.
class SkeletonDrawerTile extends StatelessWidget {
  final bool compact;
  const SkeletonDrawerTile({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 42.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
      ),
      child: Row(
        children: [
          SkeletonBox(width: size, height: size, radius: compact ? size / 2 : 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: compact ? 100 : 120, height: 12, radius: 4),
                const SizedBox(height: 6),
                SkeletonBox(width: compact ? 70 : 90, height: 9, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A ready-to-drop-in skeleton for the whole [AppDrawer] menu while
/// `GET /api/v1/modules` is loading — same tile count/shape as a typical
/// menu (top-level tiles, then a shorter "Masters"-style group).
class SkeletonDrawerMenu extends StatelessWidget {
  const SkeletonDrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SkeletonDrawerTile(),
            ),
          const SizedBox(height: 18),
          SkeletonBox(width: 90, height: 12, radius: 4),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 9),
              child: SkeletonDrawerTile(compact: true),
            ),
        ],
      ),
    );
  }
}

/// A ready-to-drop-in skeleton for any "loading" branch on a list page —
/// pass the same padding the real `ListView` uses so nothing visibly
/// shifts once data arrives.
class SkeletonListView extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;
  const SkeletonListView({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonListCard(),
      ),
    );
  }
}
