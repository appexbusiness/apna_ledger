import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.maxLength,
    this.prefixText,
    this.onChanged,
    this.inputFormatters,
    this.enabled = true,
    this.errorText,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixText;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  /// External error message (e.g. from an async check) shown below the
  /// field, independent of [validator]/[Form] validation.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefix,
            prefixText: prefixText,
            suffixIcon: suffix,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
