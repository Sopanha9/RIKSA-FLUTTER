import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Leaves a pushed learning screen, or falls back to the subject list when
/// the screen was opened directly and has nothing beneath it.
void leaveLearningScreen(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
  } else {
    context.go('/learn');
  }
}

/// A plain back bar for the moments a learning screen has no content of its
/// own: while it loads, when it fails, or when it is empty. The bottom
/// navigation is hidden on these screens, so without it a failing Retry
/// would leave no visible way out.
class LearningStatusBar extends StatelessWidget implements PreferredSizeWidget {
  const LearningStatusBar({super.key, this.title});

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return AppBar(
      key: const ValueKey('learning-status-bar'),
      backgroundColor: context.riksa.canvas,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: IconButton(
        key: const ValueKey('learning-status-back'),
        onPressed: () => leaveLearningScreen(context),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      titleSpacing: 0,
      title: title == null
          ? null
          : Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RiksaTypography.titleStyleFor(
                title,
                Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
