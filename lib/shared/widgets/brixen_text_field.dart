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
  final TextCapitalization textCapitalization;
  final int maxLines;

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
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
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

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      style: TextStyle(color: onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
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
                      colors: [widget.iconColor, widget.iconColor.withValues(alpha: 0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(color: widget.iconColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: IconTheme(
                    data: const IconThemeData(color: AppColors.white, size: 17),
                    child: widget.prefixIcon!,
                  ),
                ),
              )
            : null,
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
