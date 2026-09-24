import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shows [child] as a draggable bottom sheet — tapping outside it dismisses
/// it, same pattern as the Companies module's detail sheet. Used so tapping
/// a list card shows details in-place instead of navigating to a new page.
Future<void> showDetailSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      behavior: HitTestBehavior.opaque,
      child: builder(ctx),
    ),
  );
}

/// Common chrome for every module's detail sheet: drag handle, header
/// (avatar + title/subtitle + edit/delete), an optional status row, then a
/// scrollable list of [DetailSection]s.
class DetailSheetScaffold extends StatelessWidget {
  final String avatarText;
  final List<Color> avatarGradient;
  final IconData? avatarIcon;
  final bool showAvatar;
  final String title;
  final String? subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? statusRow;
  final List<Widget> sections;

  const DetailSheetScaffold({
    super.key,
    this.avatarText = '',
    this.avatarGradient = const [AppColors.brand, AppColors.brandDeep],
    this.avatarIcon,
    this.showAvatar = true,
    required this.title,
    this.subtitle,
    this.onEdit,
    this.onDelete,
    this.statusRow,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAvatar) ...[
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: avatarGradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.shadows([
                            BoxShadow(
                              color: avatarGradient.first.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]),
                        ),
                        child: avatarIcon != null
                            ? Icon(avatarIcon, color: AppColors.white, size: 22)
                            : Text(
                                avatarText,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: showAvatar ? 4 : 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      SheetIconButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.brand,
                        onTap: onEdit!,
                      ),
                    ],
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      SheetIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.ink,
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                ),
              ),
              if (statusRow != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: statusRow!,
                ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      sections[i],
                      if (i != sections.length - 1) const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const SheetIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const DetailSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.highlightShadow(0.85),
                blurRadius: 6,
                offset: const Offset(-2, -2),
              ),
            ]),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < items.length - 1)
                        Divider(height: 1, color: AppColors.border, indent: 60),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;
  // A short value (an amount, a status, a name) reads fine right-aligned
  // next to the label on one line. A long one (a message, notes) wrapping
  // right-aligned in that same cramped space reads congested — this puts
  // it on its own full-width, left-aligned line below the label instead.
  final bool stacked;
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.brand,
    this.stacked = false,
  });

  Widget _icon() => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.accentGradient(iconColor),
      ),
      shape: BoxShape.circle,
      boxShadow: AppColors.shadows([
        BoxShadow(
          color: iconColor.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ]),
    ),
    child: Icon(icon, size: 16, color: AppColors.white),
  );

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _icon(),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _icon(),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
