import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrixenDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;

  /// Optional smaller second line (e.g. a customer's shop name); null or
  /// empty shows just the label.
  final String? Function(T)? subtitleOf;
  final IconData icon;
  final Color iconColor;
  final void Function(T?) onChanged;

  const BrixenDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
    required this.icon,
    this.iconColor = AppColors.brand,
    required this.onChanged,
  });

  @override
  State<BrixenDropdown<T>> createState() => _BrixenDropdownState<T>();
}

class _BrixenDropdownState<T> extends State<BrixenDropdown<T>>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  OverlayEntry? _entry;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _isOpen = false;

  /// Opened above the field (not enough room below it).
  bool _openUp = false;

  /// Height the list may take where it opens.
  double _maxListHeight = _listHeight;
  static const _listHeight = 224.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _show() {
    final rb = context.findRenderObject() as RenderBox;
    final width = rb.size.width;
    final height = rb.size.height;

    // Room below and above the field (minus the keyboard and system bars);
    // open upwards when the list doesn't fit below and there's more above.
    final mq = MediaQuery.of(context);
    final top = rb.localToGlobal(Offset.zero).dy;
    const gap = 12.0;
    final below =
        mq.size.height -
        mq.viewInsets.bottom -
        mq.padding.bottom -
        (top + height) -
        gap;
    final above = top - mq.padding.top - gap;
    final wanted = _listHeight.clamp(0.0, widget.items.length * 49.0 + 2);
    _openUp = below < wanted && above > below;
    _maxListHeight = (_openUp ? above : below).clamp(96.0, _listHeight);

    _entry = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _hide,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: _openUp
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                followerAnchor: _openUp
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                offset: Offset(0, height > 0 || _openUp ? 0 : 56),
                child: SizedBox(
                  width: width,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) => Opacity(
                      opacity: _anim.value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1 - _anim.value) * (_openUp ? 6 : -6),
                        ),
                        child: _BrixenDropdownPanel<T>(
                          items: widget.items,
                          value: widget.value,
                          labelOf: widget.labelOf,
                          subtitleOf: widget.subtitleOf,
                          openUp: _openUp,
                          maxHeight: _maxListHeight,
                          onSelect: (v) {
                            widget.onChanged(v);
                            _hide();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_entry!);
    _ctrl.forward();
    setState(() => _isOpen = true);
  }

  void _hide() {
    _ctrl.reverse().then((_) {
      _entry?.remove();
      _entry = null;
      if (mounted) setState(() => _isOpen = false);
    });
  }

  void _toggle() => _isOpen ? _hide() : _show();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = widget.value != null
        ? widget.labelOf(widget.value as T)
        : null;
    final sub = widget.value != null
        ? widget.subtitleOf?.call(widget.value as T)
        : null;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
            borderRadius: _isOpen
                ? (_openUp
                      ? const BorderRadius.vertical(bottom: Radius.circular(16))
                      : const BorderRadius.vertical(top: Radius.circular(16)))
                : BorderRadius.circular(16),
            border: isDark
                ? Border.all(
                    color: _isOpen
                        ? AppColors.silver
                        : Theme.of(context).dividerColor,
                    width: _isOpen ? 1.5 : 1,
                  )
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.shadowDark.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.highlightShadow(0.85),
                      blurRadius: 6,
                      offset: const Offset(-3, -3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              isDark
                  ? Icon(widget.icon, size: 20, color: cs.onSurfaceVariant)
                  : Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.accentGradient(widget.iconColor),
                        ),
                        boxShadow: AppColors.shadows([
                          BoxShadow(
                            color: widget.iconColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 17,
                        color: AppColors.white,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label ?? widget.hint,
                      style: TextStyle(
                        color: label != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub != null && sub.trim().isNotEmpty)
                      Text(
                        sub,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrixenDropdownPanel<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String Function(T) labelOf;
  final String? Function(T)? subtitleOf;
  final void Function(T) onSelect;

  /// Opens above the field: round the top corners instead.
  final bool openUp;
  final double maxHeight;

  const _BrixenDropdownPanel({
    required this.items,
    required this.value,
    required this.labelOf,
    this.subtitleOf,
    required this.onSelect,
    this.openUp = false,
    this.maxHeight = 224,
  });

  BorderRadius get _radius => openUp
      ? const BorderRadius.vertical(top: Radius.circular(12))
      : const BorderRadius.vertical(bottom: Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? cs.surfaceContainerHighest : AppColors.lightSurface;

    if (items.isEmpty) {
      return Material(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        borderRadius: _radius,
        color: bg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            border: Border.all(
              color: AppColors.silver.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          child: Text(
            'No options available',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
    }

    return Material(
      elevation: isDark ? 0 : 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: _radius,
      color: bg,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(
            color: AppColors.silver.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) =>
                Divider(height: 1, color: Theme.of(ctx).dividerColor),
            itemBuilder: (_, i) {
              final item = items[i];
              final selected = item == value;
              final sub = subtitleOf?.call(item);
              return GestureDetector(
                onTap: () => onSelect(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  color: selected
                      ? AppColors.silver.withValues(alpha: isDark ? 0.12 : 0.07)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelOf(item),
                              style: TextStyle(
                                color: selected
                                    ? (isDark
                                          ? AppColors.silver
                                          : AppColors.lightPrimary)
                                    : cs.onSurface,
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (sub != null && sub.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      sub,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.silver
                              : AppColors.lightPrimary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
