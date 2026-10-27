import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'exact_amount.dart';

/// The app's three colours in one sweep — near-black, blue, green — for a
/// screen's top banner (Attendance, Staff Permissions, Salary Generation).
const kThemeSweep = [
  Color(0xFF15232B),
  AppColors.brandDeep,
  AppColors.brand,
  AppColors.positiveDeep,
];

const kThemeSweepGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: kThemeSweep,
  stops: [0, 0.35, 0.7, 1],
);

/// One figure on a banner. [tone] tints its tile: blue, green or black.
class BannerStat {
  final String value, label;
  final Color tone;

  /// The exact rupee amount behind a compact [value]; tap shows it.
  final double? exact;
  const BannerStat(this.value, this.label, this.tone, {this.exact});
}

/// A tile for a [BannerStat], white text on its tone.
class BannerStatTile extends StatelessWidget {
  final BannerStat stat;
  const BannerStatTile(this.stat, {super.key});

  @override
  Widget build(BuildContext context) => ExactAmount(
    amount: stat.exact,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: stat.tone.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A screen's banner: icon, title and subtitle on the theme sweep, a row
/// of [stats], then anything else ([child]).
class ThemeBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<BannerStat> stats;
  final Widget? trailing;
  final Widget? child;
  const ThemeBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.stats = const [],
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: kThemeSweepGradient,
      borderRadius: BorderRadius.circular(22),
      boxShadow: AppColors.shadows([
        BoxShadow(
          color: AppColors.brandDeep.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ]),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.positive),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, s) in stats.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: BannerStatTile(s)),
              ],
            ],
          ),
        ],
        if (child != null) ...[const SizedBox(height: 14), child!],
      ],
    ),
  );
}

/// "1 → 2 → 3": how a screen is used, each step in a theme colour; steps
/// before [current] ticked, [current] lit. Null [current] = just a guide.
class StepGuide extends StatelessWidget {
  final List<(IconData, String, String)> steps;
  final int? current;
  const StepGuide({super.key, required this.steps, this.current});

  static const _tones = [
    AppColors.brand,
    AppColors.positiveDeep,
    AppColors.brandBlack,
  ];

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, (icon, title, sub)) in steps.indexed) ...[
        if (i > 0)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ),
        Expanded(child: _step(i, icon, title, sub)),
      ],
    ],
  );

  Widget _step(int i, IconData icon, String title, String sub) {
    final tone = AppColors.isDark && i == 2
        ? AppColors.brandLight
        : _tones[i % _tones.length];
    final done = current != null && i < current!;
    final lit = current == null || i == current;
    return Opacity(
      opacity: lit || done ? 1 : 0.55,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: lit || done
                  ? LinearGradient(colors: AppColors.accentGradient(tone))
                  : null,
              color: lit || done ? null : tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: lit && current != null
                  ? [
                      BoxShadow(
                        color: tone.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 19,
              color: lit || done ? Colors.white : tone,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${i + 1}. $title',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textHint, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
