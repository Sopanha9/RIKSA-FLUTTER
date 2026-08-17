import 'package:flutter/material.dart';

/// A 64px circular social sign-in button.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.logo,
    this.onPressed,
  });

  final Widget logo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(child: logo),
        ),
      ),
    );
  }
}
