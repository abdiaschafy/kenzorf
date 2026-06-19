import 'package:flutter/material.dart';

/// Champ de saisie standard KENZORF, avec label et gestion d'erreur.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: obscureText ? 1 : maxLines,
          enabled: enabled,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
