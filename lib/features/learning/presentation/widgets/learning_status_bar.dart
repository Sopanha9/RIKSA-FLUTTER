import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_back_button.dart';

/// Leaves a pushed learning screen, or falls back to the subject list when
/// the screen was opened directly and has nothing beneath it.
void leaveLearningScreen(BuildContext context) {
  unawaited(RiksaBackButton.navigateBack(context, fallbackLocation: '/learn'));
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
      leading: const Center(
        child: RiksaBackButton(
          key: ValueKey('learning-status-back'),
          fallbackLocation: '/learn',
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
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
