import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'social_palette.dart';

/// The kinds of content a learner can write. Shared so every entry point into
/// composing — the community feed and the author's own profile — offers the
/// same three choices and lands on the same routes.
enum SocialCreateAction { post, question, article }

/// The route that composes [action].
String socialCreateRoute(SocialCreateAction action) => switch (action) {
  SocialCreateAction.article => '/blog/create',
  SocialCreateAction.question => '/community/create?type=question',
  SocialCreateAction.post => '/community/create',
};

/// Asks which kind of content to write. Returns null when dismissed.
Future<SocialCreateAction?> showSocialCreateMenu(BuildContext context) =>
    showModalBottomSheet<SocialCreateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SocialCreateMenuSheet(),
    );

class SocialCreateMenuSheet extends StatelessWidget {
  const SocialCreateMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.large),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: SocialPalette.panel(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: SocialPalette.border(context),
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.createCommunityContent,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: SocialPalette.text(context),
              ),
            ),
            const SizedBox(height: 14),
            SocialCreateOption(
              key: const ValueKey('create-post-option'),
              icon: Icons.edit_note_rounded,
              title: l10n.createPost,
              subtitle: l10n.createPostSubtitle,
              color: SocialPalette.pink(context),
              onTap: () => Navigator.pop(context, SocialCreateAction.post),
            ),
            const SizedBox(height: 10),
            SocialCreateOption(
              key: const ValueKey('create-question-option'),
              icon: Icons.help_outline_rounded,
              title: l10n.askCommunity,
              subtitle: l10n.askCommunitySubtitle,
              color: SocialPalette.aubergine(context),
              onTap: () => Navigator.pop(context, SocialCreateAction.question),
            ),
            const SizedBox(height: 10),
            SocialCreateOption(
              key: const ValueKey('create-article-option'),
              icon: Icons.auto_stories_rounded,
              title: l10n.writeArticle,
              subtitle: l10n.writeArticleSubtitle,
              color: theme.colorScheme.primary,
              onTap: () => Navigator.pop(context, SocialCreateAction.article),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialCreateOption extends StatelessWidget {
  const SocialCreateOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: SocialPalette.editorialSurface(context),
      borderRadius: AppRadii.mediumBorder,
      child: InkWell(
        borderRadius: AppRadii.mediumBorder,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: AppRadii.smallBorder,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SocialPalette.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SocialPalette.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SocialPalette.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
