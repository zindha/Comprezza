import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    super.key,
  });
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    onChanged: onChanged,
    enabled: enabled,
    obscureText: obscureText,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon,
    ),
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.onChanged,
    this.controller,
    this.hint = 'Search',
    super.key,
  });
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String hint;
  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    label: hint,
    onChanged: onChanged,
    prefixIcon: Icons.search_rounded,
    suffixIcon: IconButton(
      onPressed: controller == null
          ? null
          : () {
              controller!.clear();
              onChanged('');
            },
      tooltip: 'Clear search',
      icon: const Icon(Icons.close_rounded),
    ),
  );
}
