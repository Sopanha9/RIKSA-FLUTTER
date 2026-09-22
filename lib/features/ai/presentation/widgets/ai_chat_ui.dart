import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../mascot/domain/mascot.dart';
import '../../../mascot/presentation/widgets/mascot_face.dart';

const _userRadius = BorderRadius.only(
  topLeft: Radius.circular(AppRadii.panel),
  topRight: Radius.circular(AppRadii.panel),
  bottomLeft: Radius.circular(AppRadii.panel),
  bottomRight: Radius.circular(RiksaSpacing.xs),
);

const _tutorRadius = BorderRadius.only(
  topLeft: Radius.circular(AppRadii.panel),
  topRight: Radius.circular(AppRadii.panel),
  bottomLeft: Radius.circular(RiksaSpacing.xs),
  bottomRight: Radius.circular(AppRadii.panel),
);

double _maxBubbleWidth(BuildContext context) =>
    math.min(620, MediaQuery.sizeOf(context).width * .84);

/// The student's own message. Jade fill, never pure white text on it.
class AiUserBubble extends StatelessWidget {
  const AiUserBubble({
    super.key,
    required this.content,
    this.failed = false,
    this.onRetry,
  });

  final String content;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxBubbleWidth(context)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: failed ? palette.surfaceRaised : palette.brand,
              borderRadius: _userRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RiksaSpacing.md,
                vertical: RiksaSpacing.sm,
              ),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: failed ? palette.inkMuted : palette.onBrand,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
        if (failed) ...[
          const SizedBox(height: RiksaSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: palette.inkMuted,
              ),
              const SizedBox(width: RiksaSpacing.xxs),
              Text(
                l10n.aiMessageNotSent,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.inkMuted),
              ),
              if (onRetry != null)
                TextButton(
                  key: const ValueKey('retry-ai-message'),
                  onPressed: onRetry,
                  child: Text(l10n.aiRetryMessage),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The tutor's answer. Markdown, on a plain surface with a hairline so it reads
/// as paper rather than as a second coloured voice.
class AiTutorBubble extends StatelessWidget {
  const AiTutorBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiCoachAvatar(),
          const SizedBox(width: RiksaSpacing.xs),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _maxBubbleWidth(context) - 42,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: _tutorRadius,
                  border: Border.all(color: palette.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RiksaSpacing.md,
                    vertical: RiksaSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme)
                            .copyWith(
                              p: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                height: 1.6,
                                color: palette.ink,
                              ),
                              code: theme.textTheme.bodySmall?.copyWith(
                                backgroundColor: palette.surfaceRaised,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: palette.surfaceRaised,
                                borderRadius: AppRadii.mediumBorder,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                color: palette.learningSoft,
                                borderRadius: AppRadii.mediumBorder,
                              ),
                            ),
                      ),
                      const SizedBox(height: RiksaSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Builder(
                          builder: (context) {
                            final isKhmer =
                                Localizations.localeOf(context).languageCode ==
                                'km';
                            return Semantics(
                              button: true,
                              label: isKhmer ? 'ចម្លងចម្លើយ' : 'Copy answer',
                              child: InkWell(
                                key: const ValueKey('copy-ai-response'),
                                borderRadius: AppRadii.fullBorder,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Clipboard.setData(
                                    ClipboardData(text: content),
                                  );
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isKhmer
                                              ? 'បានចម្លងទៅក្តារតម្កល់'
                                              : 'Copied to clipboard',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: palette.inkMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isKhmer ? 'ចម្លង' : 'Copy',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: palette.inkMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coach's face beside each of its answers: the learner's own study
/// buddy, showing [face].
///
/// Beside an answer the face plays [loops] times and then rests, so a long
/// conversation is not a wall of moving heads.
class AiCoachAvatar extends StatelessWidget {
  const AiCoachAvatar({
    super.key,
    this.size = 34,
    this.face = MascotFace.happy,
    this.loops = 1,
  });

  final double size;
  final MascotFace face;
  final int? loops;

  @override
  Widget build(BuildContext context) =>
      MascotFaceAvatar(face: face, size: size, loops: loops);
}

/// Waiting state in the tutor's own position, so the answer does not arrive
/// from nowhere.
class AiThinkingBubble extends StatelessWidget {
  const AiThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    return Semantics(
      liveRegion: true,
      label: l10n.aiThinking,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiCoachAvatar(face: MascotFace.thinking, loops: null),
            const SizedBox(width: RiksaSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: _tutorRadius,
                border: Border.all(color: palette.outline),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.md,
                  vertical: RiksaSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiksaSkeleton(width: 150, height: 11),
                    SizedBox(height: RiksaSpacing.xs),
                    RiksaSkeleton(width: 96, height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names the lesson the tutor was opened from, so the student can see what it
/// already knows about.
class AiContextChip extends StatelessWidget {
  const AiContextChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RiksaSpacing.sm,
        vertical: RiksaSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.learningSoft,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 14,
            color: palette.learningStrong,
          ),
          const SizedBox(width: RiksaSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
