import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../social/presentation/widgets/social_post_card.dart'
    show socialRelativeTime;
import '../data/notification_models.dart';
import '../providers/notifications_provider.dart';

/// The notifications tab: reactions, comments, replies, article likes and
/// article reviews, newest first. Tapping a row opens what it is about.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inbox = ref.watch(notificationInboxProvider);
    final hasUnread = inbox.value?.hasUnread ?? false;
    return Scaffold(
      key: const ValueKey('notifications-screen'),
      backgroundColor: context.riksa.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiksaPageHeader(
            title: l10n.notificationsTitle,
            trailing: hasUnread
                ? TextButton(
                    key: const ValueKey('notifications-mark-all-read'),
                    onPressed: () => ref
                        .read(notificationInboxProvider.notifier)
                        .markAllRead(),
                    child: Text(l10n.notificationsMarkAllRead),
                  )
                : null,
          ),
          Expanded(
            child: switch (inbox) {
              AsyncData(:final value) => _InboxList(inbox: value),
              AsyncError() => _Centered(
                child: IllustratedEmptyState(
                  title: l10n.notificationsLoadFailed,
                  body: l10n.loadFailedCheckConnection,
                  actionLabel: l10n.tryAgain,
                  onAction: () => ref.invalidate(notificationInboxProvider),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Keeps a centred state clear of the floating tab bar.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
    child: child,
  );
}

class _InboxList extends ConsumerWidget {
  const _InboxList({required this.inbox});

  final NotificationInbox inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(notificationInboxProvider.notifier);
    final items = inbox.items;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _Centered(
                child: IllustratedEmptyState(
                  title: l10n.notificationsEmptyTitle,
                  body: l10n.notificationsEmptyBody,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.extentAfter < 400) unawaited(notifier.loadMore());
          return false;
        },
        child: ListView.separated(
          key: const ValueKey('notifications-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            RiksaSpacing.md,
            RiksaSpacing.xs,
            RiksaSpacing.md,
            // Room for the floating tab bar.
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          itemCount: items.length + (inbox.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: RiksaSpacing.xs),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(RiksaSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _NotificationTile(notification: items[index]);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final unread = !notification.read;
    final name = notification.actor?.name ?? l10n.notificationSomeone;
    final headline = switch (notification.kind) {
      NotificationKind.postReaction => l10n.notificationPostReaction(name),
      NotificationKind.commentReaction => l10n.notificationCommentReaction(
        name,
      ),
      NotificationKind.postComment => l10n.notificationPostComment(name),
      NotificationKind.commentReply => l10n.notificationCommentReply(name),
      NotificationKind.blogLike => l10n.notificationBlogLike(name),
      NotificationKind.blogApproved => l10n.notificationBlogApproved,
      NotificationKind.blogRejected => l10n.notificationBlogRejected,
      NotificationKind.other => l10n.notificationsTitle,
    };
    final preview = notification.preview;
    final location = notification.location;

    return Material(
      color: unread ? palette.brandSoft : palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        key: ValueKey('notification-${notification.id}'),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        onTap: () {
          unawaited(
            ref
                .read(notificationInboxProvider.notifier)
                .markRead(notification.id),
          );
          if (location != null) context.push(location);
        },
        child: Padding(
          padding: const EdgeInsets.all(RiksaSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Leading(notification: notification, name: name),
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (preview != null && preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      socialRelativeTime(context, notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(left: RiksaSpacing.xs, top: 6),
                  child: Container(
                    key: ValueKey('notification-unread-${notification.id}'),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: palette.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The actor's avatar with a small mark for what they did, or an article
/// icon for a moderator's review.
class _Leading extends StatelessWidget {
  const _Leading({required this.notification, required this.name});

  final AppNotification notification;
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final (IconData mark, Color markColor) = switch (notification.kind) {
      NotificationKind.postReaction ||
      NotificationKind.commentReaction ||
      NotificationKind.blogLike => (Icons.favorite_rounded, palette.saffron),
      NotificationKind.postComment || NotificationKind.commentReply => (
        Icons.chat_bubble_rounded,
        palette.brand,
      ),
      NotificationKind.blogApproved => (
        Icons.check_circle_rounded,
        palette.jade,
      ),
      NotificationKind.blogRejected => (Icons.info_rounded, palette.inkMuted),
      NotificationKind.other => (Icons.notifications_rounded, palette.brand),
    };
    final actor = notification.actor;
    final Widget face = actor == null
        ? CircleAvatar(
            radius: 21,
            backgroundColor: palette.surfaceRaised,
            child: Icon(Icons.article_rounded, color: palette.inkMuted),
          )
        : RiksaAvatarImage(
            value: actor.avatarUrl,
            label: name,
            size: 42,
            backgroundColor: palette.brandSoft,
            foregroundColor: palette.brand,
          );
    return SizedBox.square(
      dimension: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(mark, size: 13, color: markColor),
            ),
          ),
        ],
      ),
    );
  }
}
