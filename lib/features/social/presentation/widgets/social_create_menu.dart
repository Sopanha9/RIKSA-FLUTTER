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
                fontWeight: FontWeight.w600,
                color: SocialPalette.text(context),
              ),
            ),
            const SizedBox(height: 14),
            SocialCreateOption(
              key: const ValueKey('create-post-option'),
              artwork: SocialCreateArtwork.post,
              title: l10n.createPost,
              subtitle: l10n.createPostSubtitle,
              color: SocialPalette.pink(context),
              onTap: () => Navigator.pop(context, SocialCreateAction.post),
            ),
            const SizedBox(height: 10),
            SocialCreateOption(
              key: const ValueKey('create-question-option'),
              artwork: SocialCreateArtwork.question,
              title: l10n.askCommunity,
              subtitle: l10n.askCommunitySubtitle,
              color: SocialPalette.aubergine(context),
              onTap: () => Navigator.pop(context, SocialCreateAction.question),
            ),
            const SizedBox(height: 10),
            SocialCreateOption(
              key: const ValueKey('create-article-option'),
              artwork: SocialCreateArtwork.article,
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
    required this.artwork,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final SocialCreateArtwork artwork;
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
                child: Center(
                  child: SocialCreatePixelIcon(artwork: artwork, color: color),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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

enum SocialCreateArtwork { post, question, article }

class SocialCreatePixelIcon extends StatelessWidget {
  const SocialCreatePixelIcon({
    super.key,
    required this.artwork,
    required this.color,
    this.size = 34,
  });

  final SocialCreateArtwork artwork;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SocialCreatePixelPainter(artwork, color)),
  );
}

class _SocialCreatePixelPainter extends CustomPainter {
  const _SocialCreatePixelPainter(this.artwork, this.color);

  final SocialCreateArtwork artwork;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final outline = Paint()
      ..color = color.withValues(alpha: .95)
      ..style = PaintingStyle.fill;
    final dark = Paint()
      ..color = Color.lerp(color, Colors.black, .22)!
      ..style = PaintingStyle.fill;
    final light = Paint()
      ..color = Color.lerp(color, Colors.white, .44)!
      ..style = PaintingStyle.fill;
    final paper = Paint()
      ..color = Colors.white.withValues(alpha: .86)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: .2)
      ..style = PaintingStyle.fill;

    void px(Paint paint, int x, int y, [int w = 1, int h = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    switch (artwork) {
      case SocialCreateArtwork.post:
        _paintPost(px, outline, dark, light, paper, glow);
      case SocialCreateArtwork.question:
        _paintQuestion(px, outline, dark, light, paper, glow);
      case SocialCreateArtwork.article:
        _paintArticle(px, outline, dark, light, paper, glow);
    }
  }

  void _paintPost(
    void Function(Paint paint, int x, int y, [int w, int h]) px,
    Paint outline,
    Paint dark,
    Paint light,
    Paint paper,
    Paint glow,
  ) {
    px(glow, 2, 2, 12, 12);
    px(dark, 3, 2, 8, 1);
    px(dark, 2, 3, 1, 11);
    px(dark, 3, 14, 8, 1);
    px(dark, 11, 3, 1, 10);
    px(paper, 3, 3, 8, 11);
    px(light, 4, 4, 6, 1);
    px(outline, 4, 6, 5, 1);
    px(outline, 4, 8, 4, 1);
    px(outline, 4, 10, 3, 1);
    px(dark, 9, 11, 1, 1);
    px(dark, 10, 10, 1, 1);
    px(outline, 11, 8, 1, 1);
    px(outline, 12, 7, 1, 1);
    px(light, 12, 6, 2, 1);
    px(outline, 13, 5, 1, 1);
    px(dark, 13, 6, 1, 1);
    px(outline, 8, 12, 2, 1);
    px(outline, 7, 13, 1, 1);
  }

  void _paintQuestion(
    void Function(Paint paint, int x, int y, [int w, int h]) px,
    Paint outline,
    Paint dark,
    Paint light,
    Paint paper,
    Paint glow,
  ) {
    px(glow, 2, 2, 12, 11);
    px(dark, 4, 3, 8, 1);
    px(dark, 3, 4, 1, 6);
    px(dark, 12, 4, 1, 6);
    px(dark, 4, 10, 5, 1);
    px(dark, 7, 11, 1, 2);
    px(dark, 8, 12, 2, 1);
    px(paper, 4, 4, 8, 6);
    px(light, 5, 5, 6, 1);
    px(outline, 6, 5, 4, 1);
    px(outline, 10, 6, 1, 2);
    px(outline, 8, 8, 2, 1);
    px(outline, 8, 9, 1, 1);
    px(outline, 8, 11, 1, 1);
    px(light, 5, 6, 1, 1);
    px(dark, 6, 12, 1, 1);
  }

  void _paintArticle(
    void Function(Paint paint, int x, int y, [int w, int h]) px,
    Paint outline,
    Paint dark,
    Paint light,
    Paint paper,
    Paint glow,
  ) {
    px(glow, 1, 3, 14, 10);
    px(dark, 2, 4, 5, 1);
    px(dark, 9, 4, 5, 1);
    px(dark, 1, 5, 1, 8);
    px(dark, 14, 5, 1, 8);
    px(dark, 7, 5, 1, 9);
    px(dark, 8, 5, 1, 9);
    px(dark, 2, 13, 5, 1);
    px(dark, 9, 13, 5, 1);
    px(paper, 2, 5, 5, 8);
    px(paper, 9, 5, 5, 8);
    px(light, 3, 6, 3, 1);
    px(light, 10, 6, 3, 1);
    px(outline, 3, 8, 3, 1);
    px(outline, 3, 10, 3, 1);
    px(outline, 10, 8, 3, 1);
    px(outline, 10, 10, 3, 1);
    px(dark, 6, 12, 1, 1);
    px(dark, 9, 12, 1, 1);
  }

  @override
  bool shouldRepaint(covariant _SocialCreatePixelPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.color != color;
}
