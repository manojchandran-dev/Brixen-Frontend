import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Small people-and-device illustration used on auth/security screens —
/// built entirely from shapes in the brand's 4-colour palette (blue,
/// white, green, black). No external image assets, no lock icons.
class BrandIllustration extends StatelessWidget {
  final IconData deviceIcon;
  const BrandIllustration({super.key, this.deviceIcon = Icons.check_rounded});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Ground shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.shadowDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Floating accents
          Positioned(top: 6, left: 28, child: _Dot(color: AppColors.brandBlack, size: 8)),
          Positioned(top: 20, right: 26, child: _Dot(color: AppColors.positive, size: 10)),
          const Positioned(top: 52, left: 6, child: _Dot(color: AppColors.brand, size: 6)),

          // Back person (green)
          const Positioned(left: 10, bottom: 16, child: _Person(color: AppColors.positive, height: 74)),

          // Device card
          Positioned(
            bottom: 18,
            child: Container(
              width: 76,
              height: 108,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.brand, width: 2.5),
                boxShadow: AppColors.shadows([
                  BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 10)),
                ]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                    child: Icon(deviceIcon, color: AppColors.white, size: 18),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Container(
                        width: i == 1 ? 24 : 32,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Front person (blue)
          const Positioned(right: 6, bottom: 0, child: _Person(color: AppColors.brand, height: 96)),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  final Color color;
  final double height;
  const _Person({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    final headSize = height * 0.3;
    final bodyHeight = height - headSize - 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: headSize, height: headSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Container(
          width: headSize * 1.6,
          height: bodyHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(headSize),
              topRight: Radius.circular(headSize),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle));
  }
}
