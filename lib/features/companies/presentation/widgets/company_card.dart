import 'package:flutter/material.dart';
import '../../domain/entities/company.dart';
import 'status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/rich_card_shell.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final int index;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const CompanyCard({
    super.key,
    required this.company,
    this.index = 0,
    this.onDelete,
    this.onToggleStatus,
    this.onView,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = company.onboardingStatus == 'completed';
    final isPending = company.onboardingStatus == 'pending';

    final Color onboardingColor;
    final String onboardingLabel;
    if (isCompleted) {
      onboardingColor = AppColors.accentEmerald;
      onboardingLabel = 'Completed';
    } else if (isPending) {
      onboardingColor = AppColors.brandLight;
      onboardingLabel = 'Setup Pending';
    } else {
      onboardingColor = AppColors.textHint;
      onboardingLabel = 'Draft';
    }

    // Cycle each card's own background through pale tints of the same 5
    // colours used for the drawer's module icons — light shades only, so
    // text stays black/dark on every card instead of switching to white.
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
      AppColors.brandBlack,
    ];
    final accent = accentColors[index % accentColors.length];
    // Opaque blend toward white — NOT a translucent alpha colour, which
    // would let the swipe-reveal buttons show through the card underneath.
    final bg = Color.lerp(
      AppColors.surface,
      accent,
      AppColors.cardTintBlend(accent),
    )!;

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    final dividerColor = AppColors.ink.withValues(alpha: 0.12);
    final chevronBg = AppColors.ink.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwipeActions(
        onTap: () => onView?.call(),
        actions: [
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () => onEdit?.call(),
          ),
          if (isCompleted)
            SwipeAction(
              icon: company.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              label: company.isActive ? 'Inactive' : 'Active',
              color: AppColors.accentGold,
              onTap: () => onToggleStatus?.call(),
            ),
          SwipeAction(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.brandBlack,
            onTap: () => onDelete?.call(),
          ),
        ],
        child: RichCardShell(
          accentColor: onboardingColor,
          backgroundColor: bg,
          edgeColor: accent,
          showAccentBar: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Initials avatar — solid accent colour so it pops against the pale card
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.accentGradient(accent),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.shadows([
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]),
                      ),
                      child: Text(
                        company.initials,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Company info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (company.email != null &&
                              company.email!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              company.email!,
                              style: TextStyle(color: fgMuted, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: chevronBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: fgMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichCardDivider(color: dividerColor),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatCell(
                        icon: Icons.person_outline_rounded,
                        label: 'Owner',
                        value: company.ownerName,
                        valueColor: fg,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 34,
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: dividerColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _StatCell(
                        icon: Icons.apartment_rounded,
                        label: 'Industry',
                        value: company.industryType ?? '—',
                        valueColor: fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichCardDivider(color: dividerColor),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _StatCell(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Plan',
                        value: company.subscriptionPlan ?? '—',
                        valueColor: fg,
                      ),
                    ),
                    if (isCompleted)
                      StatusBadge(isActive: company.isActive)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: onboardingColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          onboardingLabel,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + uppercase label above a bold value — the "Owner / Industry / Plan"
/// cells inside a company card. Icon and label share the same neutral tone
/// so only the value itself stands out.
class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textHint),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
