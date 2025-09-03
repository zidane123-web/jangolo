import 'package:flutter/material.dart';

class OutlinedFloatingField extends StatelessWidget {
  const OutlinedFloatingField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints = const <String>[],
    this.obscureText = false,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String> autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    // Palette de couleurs finale
    const activeBorderColor = Color(0xFF009688); // Vert foncé
    const inactiveBorderColor = Color(0xFF80CBC4); // Vert clair
    const labelColor = Color(0xFF5F6368); // Gris pour le label
    const inputTextColor = Color(0xFF000000);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: inputTextColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: labelColor), // Gris
        floatingLabelStyle: const TextStyle(
          color: labelColor, // Gris aussi
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inactiveBorderColor, width: 1.6), // Vert clair
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: activeBorderColor, width: 2), // Vert foncé
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}