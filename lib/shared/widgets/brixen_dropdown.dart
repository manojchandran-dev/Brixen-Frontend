import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrixenDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final IconData icon;
  final void Function(T?) onChanged;

  const BrixenDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.icon,
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
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

    _entry = OverlayEntry(builder: (ctx) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hide,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(0, height > 0 ? 0 : 56),
              child: SizedBox(
                width: width,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => Opacity(
                    opacity: _anim.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _anim.value) * -6),
                      child: _BrixenDropdownPanel<T>(
                        items: widget.items,
                        value: widget.value,
                        labelOf: widget.labelOf,
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
    });

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
    final label =
        widget.value != null ? widget.labelOf(widget.value as T) : null;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
            borderRadius: _isOpen
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.silver
                  : Theme.of(context).dividerColor,
              width: _isOpen ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label ?? widget.hint,
                  style: TextStyle(
                    color: label != null
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant, size: 22),
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
  final void Function(T) onSelect;

  const _BrixenDropdownPanel({
    required this.items,
    required this.value,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? cs.surfaceContainerHighest : AppColors.lightSurface;

    if (items.isEmpty) {
      return Material(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(12)),
        color: bg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(
                color: AppColors.silver
                    .withValues(alpha: isDark ? 0.3 : 0.2)),
          ),
          child: Text('No options available',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 14)),
        ),
      );
    }

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(12)),
      color: bg,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 224),
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border.all(
              color:
                  AppColors.silver.withValues(alpha: isDark ? 0.3 : 0.2)),
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
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
              return GestureDetector(
                onTap: () => onSelect(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  color: selected
                      ? AppColors.silver
                          .withValues(alpha: isDark ? 0.12 : 0.07)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelOf(item),
                          style: TextStyle(
                            color: selected
                                ? (isDark
                                    ? AppColors.silver
                                    : AppColors.lightTextPrimary)
                                : cs.onSurface,
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.silver
                                : AppColors.lightTextPrimary),
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
