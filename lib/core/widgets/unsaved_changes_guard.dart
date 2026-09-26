import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Makes leaving a form with unsaved work a choice rather than an accident.
///
/// System back, the back gesture and any close button that calls
/// [Navigator.maybePop] all pass through here. A clean form closes at once;
/// a dirty one asks first; a form that is still submitting stays put until
/// the result is known. Successful saves should close with `context.pop`,
/// which skips the question.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.dirty,
    this.busy = false,
    required this.child,
  });

  final bool dirty;
  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      final navigator = Navigator.of(context);
      if (await confirmDiscardChanges(context) && navigator.mounted) {
        navigator.pop(result);
      }
    },
    child: child,
  );
}

/// Asks whether to throw away unsaved work. True means discard.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('discard-changes-dialog'),
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesBody),
      actions: [
        TextButton(
          key: const ValueKey('discard-changes-keep'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.keepEditing),
        ),
        TextButton(
          key: const ValueKey('discard-changes-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(l10n.discardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
