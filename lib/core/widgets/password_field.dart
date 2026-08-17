import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// A password input with a visibility toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outline;

    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      height: 52,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      suffix: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: muted,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
