import 'package:flutter/material.dart';

/// A rounded surface container with a subtle border.
/// Shrink-wraps its content by default; set [fullWidth] to stretch.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.fullWidth = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outline),
    );
    final content = SizedBox(
      width: fullWidth ? double.infinity : null,
      child: onTap == null
          ? Container(
              padding: padding,
              decoration: decoration,
              child: child,
            )
          : Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: padding,
                  decoration: decoration,
                  child: child,
                ),
              ),
            ),
    );

    return fullWidth ? content : Center(child: content);
  }
}
