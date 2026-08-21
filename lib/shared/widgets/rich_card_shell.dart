import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Outer shell used by every module's list card: a colored left accent
/// strip + rounded elevated container + tap handler. Keeps the visual
/// language (radius, shadow, accent bar) consistent across modules.
class RichCardShell extends StatelessWidget {
  final Color accentColor;
  final List<Color>? accentGradient;
  final Color? backgroundColor;
  final bool showAccentBar;
  // A solid color+shadow "hard edge" on the right/bottom sides, like the
  // card is a solid block sitting on the page — a stronger 3D cue than a
  // blurred drop shadow alone. Pass the card's own saturated accent hue.
  final Color? edgeColor;
  final VoidCallback? onTap;
  final Widget child;

  const RichCardShell({
    super.key,
    required this.accentColor,
    this.accentGradient,
    this.backgroundColor,
    this.showAccentBar = true,
    this.edgeColor,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppColors.surface);
    // On a strongly saturated card (e.g. a fully solid brand/positive fill),
    // tint both shadow layers with the card's own hue instead of neutral
    // ink/white. A pale tint (close to white, like the Companies list
    // cards) still wants the neutral pairing — the heavier tinted shadow
    // reads too dark against something that light.
    final isPale = backgroundColor != null && HSLColor.fromColor(backgroundColor!).lightness > 0.8;
    final tinted = backgroundColor != null && backgroundColor != AppColors.surface && !isPale;
    final shadowDark = tinted ? Colors.black.withValues(alpha: 0.24) : AppColors.ink.withValues(alpha: 0.11);
    final shadowLight = tinted ? Colors.white.withValues(alpha: 0.2) : AppColors.white.withValues(alpha: 0.9);

    final card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: edgeColor == null
            ? null
            : Border(
                right: BorderSide(color: edgeColor!, width: 2.5),
                bottom: BorderSide(color: edgeColor!, width: 5),
              ),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]
            : [
                if (edgeColor != null) BoxShadow(color: edgeColor!.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(2, 6)),
                BoxShadow(color: shadowDark, blurRadius: 22, offset: const Offset(0, 10)),
                BoxShadow(color: shadowLight, blurRadius: 10, offset: const Offset(-4, -4)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showAccentBar)
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentGradient == null ? accentColor : null,
                    gradient: accentGradient == null
                        ? null
                        : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: accentGradient!),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// A single swipe-reveal action button's spec.
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Wraps [child] with swipe-left-to-reveal action buttons (iOS-style),
/// built with plain gesture handling — no extra package needed. Replaces
/// the old 3-dot menu with a swipe gesture for a more modern feel.
class SwipeActions extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final List<SwipeAction> actions;

  const SwipeActions({
    super.key,
    required this.child,
    required this.onTap,
    required this.actions,
  });

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions> {
  static const _buttonWidth = 72.0;
  double _dragExtent = 0;

  double get _actionsWidth => _buttonWidth * widget.actions.length;

  void _close() {
    if (_dragExtent != 0) setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                const Spacer(),
                for (final action in widget.actions)
                  _SwipeActionButton(
                    icon: action.icon,
                    label: action.label,
                    color: action.color,
                    width: _buttonWidth,
                    onTap: () {
                      _close();
                      action.onTap();
                    },
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _dragExtent != 0 ? _close() : widget.onTap(),
          onHorizontalDragUpdate: (d) => setState(
              () => _dragExtent = (_dragExtent + d.delta.dx).clamp(-_actionsWidth, 0)),
          onHorizontalDragEnd: (d) => setState(
              () => _dragExtent = _dragExtent < -_actionsWidth / 2 ? -_actionsWidth : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragExtent, 0, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final VoidCallback onTap;
  const _SwipeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal rule used between a card's header/stats/footer sections.
class RichCardDivider extends StatelessWidget {
  final Color? color;
  const RichCardDivider({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: color ?? Theme.of(context).dividerColor);
  }
}

/// A single label/value pair inside a [StatGrid].
class StatGridItem {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  const StatGridItem({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });
}

/// Row of 2-4 label/value stats separated by vertical dividers — the
/// "mini stats grid" section inside a rich list card.
class StatGrid extends StatelessWidget {
  final List<StatGridItem> items;
  final Color? labelColor;
  final Color? valueColor;
  final Color? dividerColor;
  const StatGrid({super.key, required this.items, this.labelColor, this.valueColor, this.dividerColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 28,
                child: VerticalDivider(width: 1, thickness: 1, color: dividerColor ?? Theme.of(context).dividerColor),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items[i].label,
                  style: TextStyle(fontSize: 10, color: labelColor ?? cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  items[i].value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: items[i].bold ? FontWeight.w700 : FontWeight.w600,
                    color: items[i].color ?? valueColor ?? cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
