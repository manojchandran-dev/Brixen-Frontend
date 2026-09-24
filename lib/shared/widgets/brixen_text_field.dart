import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrixenTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Color iconColor;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool readOnly;

  const BrixenTextField({
    super.key,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.iconColor = AppColors.brand,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  State<BrixenTextField> createState() => _BrixenTextFieldState();
}

class _BrixenTextFieldState extends State<BrixenTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    // Material's InputDecorator always vertically centers `prefixIcon`
    // across the *entire* field height, label float or not — it's a fixed
    // internal layout rule (`centerLayout`), not something a wrapper widget
    // can override. For a multi-line field that puts the icon nowhere near
    // the first line. `label` (a widget, not just `labelText`), by
    // contrast, is positioned at the top via `alignLabelWithHint` like any
    // other multi-line field's label — so for maxLines > 1 the icon rides
    // inside the label itself instead of the separate prefixIcon slot, and
    // shrinks/floats together with it exactly like the label text does.
    final multiline = widget.maxLines > 1;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      readOnly: widget.readOnly,
      style: TextStyle(
        color: widget.readOnly ? onSurfaceVariant : onSurface,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: multiline ? null : widget.label,
        label: multiline && widget.prefixIcon != null
            ? _IconLabel(
                icon: widget.prefixIcon!,
                color: widget.iconColor,
                text: widget.label,
              )
            : (multiline ? Text(widget.label) : null),
        hintText: widget.hint,
        alignLabelWithHint: multiline,
        prefixIcon: multiline || widget.prefixIcon == null
            ? null
            : BrixenPrefixIcon(icon: widget.prefixIcon!, color: widget.iconColor),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}

class BrixenPrefixIcon extends StatelessWidget {
  final Widget icon;
  final Color color;
  const BrixenPrefixIcon({super.key, required this.icon, this.color = AppColors.brand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.accentGradient(color),
          ),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]),
        ),
        child: IconTheme(
          data: const IconThemeData(color: AppColors.white, size: 17),
          child: icon,
        ),
      ),
    );
  }
}

/// A compact icon + text pairing used as a multi-line field's `label`
/// widget — floats and shrinks together as one unit, same as the label
/// text alone would.
class _IconLabel extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String text;
  const _IconLabel({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: AppColors.accentGradient(color)),
          ),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.white, size: 13),
            child: icon,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
