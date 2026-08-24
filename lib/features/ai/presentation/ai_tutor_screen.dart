import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';

class AiTutorScreen extends StatelessWidget {
  const AiTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        key: const PageStorageKey('ai-tutor-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: RiksaPageHeader(
              title: l10n.aiTutor,
              subtitle: l10n.learningHeaderSubtitle,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: IllustratedEmptyState(
              title: l10n.aiTutor,
              body: l10n.aiTutorComingSoon,
              actionLabel: l10n.learn,
              onAction: () => context.go('/learn'),
            ),
          ),
        ],
      ),
    );
  }
}
