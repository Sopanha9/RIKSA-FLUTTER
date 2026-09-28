import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The notifications tab.
///
/// The server does not record notifications yet, so this is honestly empty
/// rather than filled with made-up activity. Replies, reactions and article
/// reviews will land here once the backend creates them.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: const ValueKey('notifications-screen'),
      backgroundColor: context.riksa.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiksaPageHeader(title: l10n.notificationsTitle),
          Expanded(
            child: Padding(
              // Keep the empty state clear of the floating tab bar.
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: IllustratedEmptyState(
                title: l10n.notificationsEmptyTitle,
                body: l10n.notificationsEmptyBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
