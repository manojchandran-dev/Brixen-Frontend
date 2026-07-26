import 'package:flutter/material.dart';

class BrixenTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  const BrixenTextField({
    super.key,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
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
      style: TextStyle(color: onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? IconTheme(
                data: IconThemeData(color: onSurfaceVariant, size: 20),
                child: widget.prefixIcon!,
              )
            : null,
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
