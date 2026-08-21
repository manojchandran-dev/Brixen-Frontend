import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A purely decorative "welcome" dashboard shown in place of a module
/// that has no real data behind it yet — same rich visual language as the
/// finished dashboards (hero stat, dot chart, split card, status card),
/// but every number here is illustrative, not live data.
class WelcomeDashboardView extends StatelessWidget {
  const WelcomeDashboardView({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // Static, illustrative pattern — not tied to any live data source.
    const weekly = [1, 1, 2, 1, 2, 3, 2, 2, 1, 3, 3];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text('${_greeting()} 👋', style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
            const Icon(Icons.search_rounded, color: AppColors.ink, size: 24),
            const SizedBox(width: 16),
            Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
              Positioned(top: -1, right: -1, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle))),
            ]),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Welcome to your Brixen workspace', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),

        // ── Hero card ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 12, offset: const Offset(-6, -6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('24', style: TextStyle(color: AppColors.ink, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('On Track', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.trending_up_rounded, size: 14, color: AppColors.white),
                    ]),
                  ),
                  const Spacer(),
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                    child: const Center(child: Text('B', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Everything, at a glance', style: TextStyle(color: AppColors.textHint, fontSize: 12.5)),
              const SizedBox(height: 22),
              SizedBox(
                height: 3 * 10 + 2 * 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(weekly.length, (i) {
                    final light = weekly[i] <= 1 || (i.isEven && weekly[i] < 3);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(weekly[i], (r) {
                        return Padding(
                          padding: EdgeInsets.only(top: r == 0 ? 0 : 6),
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: light ? AppColors.brandLight : AppColors.brand),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Split card ────────────────────────────────────────────
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _SplitHalf(filled: true, label: 'Getting\nstarted')),
            const SizedBox(width: 12),
            Expanded(child: _SplitHalf(filled: false, label: 'Set up\nremaining')),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Status card ───────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 26, offset: const Offset(0, 14)),
              BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 12, offset: const Offset(-6, -6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your workspace', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('Ready to grow', style: TextStyle(color: AppColors.ink, fontSize: 21, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40, width: 62,
                    child: Stack(children: List.generate(2, (i) {
                      return Positioned(
                        left: i * 24.0,
                        child: Container(
                          width: 40, height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0 ? AppColors.brand : AppColors.positive,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 2.5),
                          ),
                          child: const Icon(Icons.person, color: AppColors.white, size: 19),
                        ),
                      );
                    })),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Row(children: [
                Text('Set up', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                Spacer(),
                Text('Remaining', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: Row(children: List.generate(18, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: i < 12 ? AppColors.positive : AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                    ),
                  );
                })),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _Legend(color: AppColors.positive, label: 'Completed'),
                const SizedBox(width: 20),
                _Legend(color: AppColors.surfaceElevated, label: 'Remaining', bordered: true),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitHalf extends StatelessWidget {
  final bool filled;
  final String label;
  const _SplitHalf({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: filled ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: filled
            ? [
                BoxShadow(color: AppColors.brandDeep.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.brandLight.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(-5, -5)),
              ]
            : [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(-5, -5)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: filled ? Colors.white.withValues(alpha: 0.16) : AppColors.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 16, color: filled ? AppColors.white : AppColors.brand),
          ),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700, height: 1.25)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  const _Legend({required this.color, required this.label, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: bordered ? Border.all(color: AppColors.border) : null)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}
