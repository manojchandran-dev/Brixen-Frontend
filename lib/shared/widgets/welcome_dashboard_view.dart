import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import 'skeleton.dart';

/// The main "Dashboard" tab — backed by a single aggregate call,
/// `GET /api/v1/dashboard/summary`, instead of pulling the full
/// companies/employees/sales lists and aggregating client-side.
class WelcomeDashboardView extends ConsumerWidget {
  const WelcomeDashboardView({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Header band tints by time of day — morning/afternoon/evening/night —
  // all still built from the brand's own blue/green/black set, just
  // shifted in depth, rather than introducing warm sunrise/sunset hues.
  static List<Color> _sessionGradient() {
    final h = DateTime.now().hour;
    if (h < 12) {
      return [
        AppColors.brandPale,
        AppColors.brandLight,
      ]; // morning — crisp, pale
    }
    if (h < 17) {
      return [
        AppColors.brandLight,
        AppColors.brand,
      ]; // afternoon — full brand blue
    }
    if (h < 21) {
      return [AppColors.brand, AppColors.brandDeep]; // evening — deeper blue
    }
    return [AppColors.brandDeep, AppColors.brandBlack]; // night — near-black
  }

  static bool _sessionIsDark() {
    final h = DateTime.now().hour;
    return h >= 17;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const _DashboardSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e.toString(),
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (summary) => _DashboardContent(summary: summary),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  const _DashboardContent({required this.summary});

  // Placeholder figures shown only until real records exist, so the
  // dashboard doesn't render as an empty/broken screen on a fresh
  // workspace.
  static const _placeholderWeekly = [1, 1, 2, 1, 2, 3, 2, 2, 1, 3, 3];
  static const _placeholderTotal = 24;
  static const _placeholderActive = 18;
  static const _placeholderEmployees = 12;
  static const _placeholderPlanName = 'Professional';
  static const _placeholderShare = 0.65;

  @override
  Widget build(BuildContext context) {
    final hasCompanies = summary.totalCompanies > 0;

    final totalCompanies = hasCompanies
        ? summary.totalCompanies
        : _placeholderTotal;
    final activeCompanies = hasCompanies
        ? summary.activeCompanies
        : _placeholderActive;
    final weekly = hasCompanies
        ? summary.weeklySignups.map((w) => w.count).toList()
        : _placeholderWeekly;
    final employeesCount = summary.totalEmployees > 0
        ? summary.totalEmployees
        : _placeholderEmployees;

    final sortedPlans = [...summary.subscriptionPlans]
      ..sort((a, b) => b.count.compareTo(a.count));
    final topPlan = sortedPlans.isEmpty ? null : sortedPlans.first;
    final topPlanName = topPlan?.plan ?? _placeholderPlanName;
    final topPlanShare = hasCompanies && topPlan != null
        ? (topPlan.count / summary.totalCompanies)
        : _placeholderShare;
    final filledSegments = (topPlanShare * 18).round();

    final recentSales = summary.recentSales;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Builder(
          builder: (context) {
            final sessionDark = WelcomeDashboardView._sessionIsDark();
            final fg = sessionDark ? AppColors.white : AppColors.ink;
            final fgMuted = sessionDark
                ? AppColors.white.withValues(alpha: 0.75)
                : AppColors.textSecondary;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: WelcomeDashboardView._sessionGradient(),
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.shadows([
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${WelcomeDashboardView._greeting()} 👋',
                          style: TextStyle(
                            color: fg,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Icon(Icons.search_rounded, color: fg, size: 24),
                      const SizedBox(width: 16),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: fg,
                            size: 24,
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.positive,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to your Brixen workspace',
                    style: TextStyle(color: fgMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // ── Hero card — total companies + weekly signup trend ──────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.highlightShadow(0.9),
                blurRadius: 12,
                offset: const Offset(-6, -6),
              ),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$totalCompanies',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.positive,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$activeCompanies Active',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Companies onboarded',
                style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final maxWeekly = weekly.fold<int>(
                    1,
                    (a, b) => b > a ? b : a,
                  );
                  return SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(weekly.length, (i) {
                        final barHeight = 6.0 + (weekly[i] / maxWeekly) * 34.0;
                        final isLast = i == weekly.length - 1;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.5,
                            ),
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isLast
                                      ? [AppColors.brand, AppColors.brandDeep]
                                      : [
                                          AppColors.brandLight.withValues(
                                            alpha: 0.8,
                                          ),
                                          AppColors.brandLight.withValues(
                                            alpha: 0.5,
                                          ),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Weekly signups · last 11 weeks',
                style: TextStyle(color: AppColors.textHint, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Split card — Companies / Employees counts ───────────────
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _KpiHalf(
                  filled: true,
                  icon: Icons.business_rounded,
                  value: '$totalCompanies',
                  label: 'Companies',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiHalf(
                  filled: false,
                  icon: Icons.badge_rounded,
                  value: '$employeesCount',
                  label: 'Employees',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Status card — subscription plan breakdown ────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.highlightShadow(0.9),
                blurRadius: 12,
                offset: const Offset(-6, -6),
              ),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscription Plans',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$topPlanName leads',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 62,
                    child: Stack(
                      children: List.generate(2, (i) {
                        return Positioned(
                          left: i * 24.0,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.brand
                                  : AppColors.positive,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.business_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    topPlanName,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Other Plans',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: Row(
                  children: List.generate(18, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i < filledSegments
                              ? AppColors.positive
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Legend(color: AppColors.positive, label: topPlanName),
                  const SizedBox(width: 20),
                  _Legend(
                    color: AppColors.surfaceElevated,
                    label: 'Other Plans',
                    bordered: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Recent Sales ───────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.highlightShadow(0.9),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Recent Sales',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (recentSales.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push(AppRouter.sales),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              color: AppColors.brand,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.brand,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (recentSales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          size: 18,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No sales recorded yet — create your first invoice to see it here.',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...(() {
                  final top3 = recentSales.take(3).toList();
                  return top3.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == top3.length - 1 ? 0 : 12,
                      ),
                      child: _RecentSaleRow(sale: entry.value),
                    );
                  });
                })(),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiHalf extends StatelessWidget {
  final bool filled;
  final IconData icon;
  final String value;
  final String label;
  const _KpiHalf({
    required this.filled,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: filled ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: filled
            ? AppColors.shadows([
                BoxShadow(
                  color: AppColors.brandDeep.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.brandLight.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ])
            : AppColors.shadows([
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.highlightShadow(0.9),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white.withValues(alpha: 0.16)
                  : AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: filled ? AppColors.white : AppColors.brand,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: filled
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppColors.textHint,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  const _Legend({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: bordered ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  final RecentSaleSummary sale;
  const _RecentSaleRow({required this.sale});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.positive;
      case 'partial':
        return AppColors.brand;
      default:
        return AppColors.brandLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final statusColor = _statusColor(sale.status);
    final title = sale.customerName;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor, statusColor.withValues(alpha: 0.75)],
            ),
            shape: BoxShape.circle,
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: statusColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]),
          ),
          child: Text(
            title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('d MMM yyyy').format(sale.date),
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${fmt.format(sale.amount)}',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              sale.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mirrors the real dashboard's hero / split / status / recent-sales shape
/// so nothing jumps in size once the summary call resolves.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              const SkeletonBox(width: 170, height: 24, radius: 6),
              const Spacer(),
              const SkeletonBox(width: 24, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 8),
          const SkeletonBox(width: 210, height: 13, radius: 4),
          const SizedBox(height: 20),

          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonBox(width: 64, height: 42, radius: 8),
                    const SizedBox(width: 10),
                    const SkeletonBox(width: 84, height: 26, radius: 20),
                    const Spacer(),
                    const SkeletonBox(width: 44, height: 44, radius: 22),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonBox(width: 130, height: 12, radius: 4),
                const SizedBox(height: 22),
                const SkeletonBox(height: 40, radius: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Split card
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _skeletonCard(height: 128)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonCard(height: 128)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _skeletonCard(height: 200),
          const SizedBox(height: 20),
          _skeletonCard(height: 190),
        ],
      ),
    );
  }

  Widget _skeletonCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 110, height: 14, radius: 4),
          const Spacer(),
          const SkeletonBox(height: 10, radius: 4),
          const SizedBox(height: 8),
          const SkeletonBox(width: 130, height: 10, radius: 4),
        ],
      ),
    );
  }
}
