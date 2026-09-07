import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/ai_chat_models.dart';

/// Coarse buckets the chat list is grouped under, newest first.
enum AiChatGroup { today, thisWeek, earlier }

AiChatGroup aiChatGroupFor(DateTime? updatedAt, DateTime now) {
  if (updatedAt == null) return AiChatGroup.earlier;
  final local = updatedAt.toLocal();
  final startOfToday = DateTime(now.year, now.month, now.day);
  if (!local.isBefore(startOfToday)) return AiChatGroup.today;
  if (!local.isBefore(startOfToday.subtract(const Duration(days: 6)))) {
    return AiChatGroup.thisWeek;
  }
  return AiChatGroup.earlier;
}

typedef AiChatSection = ({AiChatGroup group, List<AiChatSession> chats});

/// Sorts newest first and splits the run into dated sections, so the list stops
/// reading as one undifferentiated column.
List<AiChatSection> groupAiChats(List<AiChatSession> chats, {DateTime? now}) {
  final moment = now ?? DateTime.now();
  final sorted = [...chats]
    ..sort((a, b) {
      final left = a.updatedAt;
      final right = b.updatedAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  final sections = <AiChatSection>[];
  for (final group in AiChatGroup.values) {
    final chatsInGroup = sorted
        .where((chat) => aiChatGroupFor(chat.updatedAt, moment) == group)
        .toList();
    if (chatsInGroup.isNotEmpty) {
      sections.add((group: group, chats: chatsInGroup));
    }
  }
  return sections;
}

String aiChatGroupLabel(AppLocalizations l10n, AiChatGroup group) =>
    switch (group) {
      AiChatGroup.today => l10n.aiChatsToday,
      AiChatGroup.thisWeek => l10n.aiChatsThisWeek,
      AiChatGroup.earlier => l10n.aiChatsEarlier,
    };

/// Short relative stamp: `now`, `4m`, `7h`, `3d`, `12 Jan`.
String aiChatTimeLabel(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final l10n = AppLocalizations.of(context)!;
  final local = date.toLocal();
  final now = DateTime.now();
  final elapsed = now.difference(local);
  final language = Localizations.localeOf(context).languageCode;
  if (elapsed.isNegative || elapsed.inMinutes < 1) return l10n.aiTimeNow;
  if (elapsed.inMinutes < 60) return l10n.aiTimeMinutes(elapsed.inMinutes);
  if (elapsed.inHours < 24) return l10n.aiTimeHours(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.aiTimeDays(elapsed.inDays);
  if (local.year == now.year) return DateFormat.MMMd(language).format(local);
  return DateFormat.yMMMd(language).format(local);
}

/// The one resumable conversation, given the single pastel surface this screen
/// is allowed. Everything below it is a quiet white row.
class AiFocalChatCard extends StatelessWidget {
  const AiFocalChatCard({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  final AiChatSession chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final title = chat.displayTitle(l10n.aiChatFallbackTitle);
    final preview = chat.previewText == title ? null : chat.previewText;
    return RiksaPastelCard(
      tone: RiksaPastelTone.blush,
      padding: const EdgeInsets.fromLTRB(
        RiksaSpacing.md,
        RiksaSpacing.sm,
        RiksaSpacing.xs,
        RiksaSpacing.md,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: palette.jadeStrong),
              const SizedBox(width: RiksaSpacing.xxs),
              Text(
                l10n.aiContinueChat.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.jadeStrong,
                  letterSpacing: .6,
                ),
              ),
              const Spacer(),
              Text(
                aiChatTimeLabel(context, chat.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              _AiChatMenuButton(onDelete: onDelete),
            ],
          ),
          const SizedBox(height: RiksaSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: RiksaSpacing.xs),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: RiksaTypography.titleStyleFor(
                title,
                theme.textTheme.headlineSmall,
              ),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: RiksaSpacing.xxs),
            Padding(
              padding: const EdgeInsets.only(right: RiksaSpacing.xs),
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A quiet row: what the chat is about, what was last said, and when.
class AiChatRow extends StatelessWidget {
  const AiChatRow({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  final AiChatSession chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final title = chat.displayTitle(l10n.aiChatFallbackTitle);
    // A single-message chat would otherwise print the same sentence twice.
    final preview = chat.previewText == title ? null : chat.previewText;
    return Semantics(
      container: true,
      child: Material(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.largeBorder,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RiksaSpacing.md,
              RiksaSpacing.sm,
              RiksaSpacing.xs,
              RiksaSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RiksaTypography.titleStyleFor(
                                title,
                                theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                          const SizedBox(width: RiksaSpacing.xs),
                          Text(
                            aiChatTimeLabel(context, chat.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.inkFaint,
                            ),
                          ),
                        ],
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _AiChatMenuButton(onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiChatMenuButton extends StatelessWidget {
  const _AiChatMenuButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.aiChatOptions,
      icon: Icon(Icons.more_horiz_rounded, color: context.riksa.inkMuted),
      iconSize: 22,
      padding: EdgeInsets.zero,
      splashRadius: 22,
      // The app's icon buttons carry a white disc, which would sit as a
      // visible circle on the pastel focal card.
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        minimumSize: const Size.square(44),
      ),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'delete', child: Text(l10n.aiDeleteChat)),
      ],
    );
  }
}

/// Loading state in the shape of the list it becomes, not a spinner.
class AiChatRowSkeleton extends StatelessWidget {
  const AiChatRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.riksa.surface,
      borderRadius: AppRadii.largeBorder,
    ),
    child: const Padding(
      padding: EdgeInsets.all(RiksaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiksaSkeleton(width: 180, height: 15),
          SizedBox(height: RiksaSpacing.xs),
          RiksaSkeleton(width: 240, height: 11),
        ],
      ),
    ),
  );
}

/// Openers that turn a blank tutor into a first question. Seeded with the
/// lesson the student came from when there is one.
List<String> aiStarterPrompts(AppLocalizations l10n) => [
  l10n.aiStarterExplainAgain,
  l10n.aiStarterStillUnsure,
  l10n.aiStarterWorkedExample,
];

class AiStarterPrompts extends StatelessWidget {
  const AiStarterPrompts({super.key, required this.onSelected, this.prompts});

  final ValueChanged<String> onSelected;
  final List<String>? prompts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = prompts ?? aiStarterPrompts(l10n);
    return Wrap(
      spacing: RiksaSpacing.xs,
      runSpacing: RiksaSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final prompt in items)
          ActionChip(
            key: ValueKey('ai-starter-$prompt'),
            label: Text(prompt),
            onPressed: () => onSelected(prompt),
          ),
      ],
    );
  }
}
