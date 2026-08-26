import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Full-body placeholder for a feature that isn't built yet — a raised,
/// glowing icon badge (blue↔green) over a soft radial highlight, plus
/// heading/subtitle copy. Used wherever a module has no backend yet.
class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ComingSoonView({
    super.key,
    this.icon = Icons.auto_awesome_rounded,
    this.title = 'Coming Soon',
    this.subtitle = "We're building this. It'll be ready before you know it.",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brand.withValues(alpha: 0.14),
                        AppColors.positive.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brand, AppColors.brandDeep],
                    ),
                    boxShadow: AppColors.shadows([
                      BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 14)),
                      BoxShadow(color: AppColors.highlightShadow(0.7), blurRadius: 10, offset: const Offset(-4, -4)),
                    ]),
                  ),
                  child: Icon(icon, color: AppColors.white, size: 44),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.positive,
                      border: Border.all(color: AppColors.background, width: 3),
                      boxShadow: AppColors.shadows([BoxShadow(color: AppColors.positive.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: AppColors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(title, style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.positive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt_rounded, size: 14, color: AppColors.positive),
                SizedBox(width: 5),
                Text('In active development', style: TextStyle(color: AppColors.positive, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
