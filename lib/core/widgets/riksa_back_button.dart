import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef RiksaBackConfirmation = FutureOr<bool> Function(BuildContext context);

/// A back control that returns to a sensible route when opened directly.
///
/// When a route is on the stack, [Navigator.maybePop] keeps pop handlers
/// such as unsaved-change guards in control. A direct route has no
/// prior page to pop, so it goes to [fallbackLocation] instead.
class RiksaBackButton extends StatelessWidget {
  const RiksaBackButton({
    super.key,
    required this.fallbackLocation,
    this.confirmFallback,
    this.style,
    this.icon = Icons.arrow_back_rounded,
    this.iconSize,
    this.result,
    this.onPressed,
    this.constraints,
  });

  final String fallbackLocation;
  final RiksaBackConfirmation? confirmFallback;
  final ButtonStyle? style;
  final IconData icon;
  final double? iconSize;
  final Object? result;
  final VoidCallback? onPressed;
  final BoxConstraints? constraints;

  /// Performs the same pop-or-fallback behavior for custom back controls.
  ///
  /// Pass [saved] after a form has been saved: the page then closes at once
  /// instead of asking its [PopScope], which has not rebuilt yet and would
  /// still treat the form as unsaved.
  static Future<void> navigateBack(
    BuildContext context, {
    required String fallbackLocation,
    Object? result,
    RiksaBackConfirmation? confirmFallback,
    bool saved = false,
  }) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Plain Navigator routes (including modal flows and tests) need to be
      // popped before consulting GoRouter's route stack.
      if (saved) {
        navigator.pop(result);
      } else {
        await navigator.maybePop(result);
      }
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop(result);
      return;
    }

    if (!saved && confirmFallback != null && !await confirmFallback(context)) {
      return;
    }
    if (!context.mounted) return;
    router?.go(fallbackLocation);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed:
        onPressed ??
        () => unawaited(
          navigateBack(
            context,
            fallbackLocation: fallbackLocation,
            result: result,
            confirmFallback: confirmFallback,
          ),
        ),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    style: style,
    constraints: constraints,
    icon: Icon(icon, size: iconSize),
  );
}
