import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../learning/providers/learning_home_provider.dart';
import '../../../mascot/domain/buddy_behavior.dart';
import '../../../mascot/presentation/widgets/buddy_companion.dart';
import '../../../mascot/providers/buddy_preferences_provider.dart';
import '../../../social/providers/social_feed_provider.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/providers/profile_provider.dart';

extension HomeRefresh on WidgetRef {
  Future<void> refreshHomeStudy() async {
    invalidate(learningHomeProvider);
    try {
      await refresh(learningHomeProvider.future);
    } on Object {
      // The section renders its own retry state.
    }
  }
}

class HomeIdentityHeader extends ConsumerStatefulWidget {
  const HomeIdentityHeader({
    super.key,
    required this.name,
    required this.streak,
    required this.reaction,
  });
  final String name;
  final int streak;
  final BuddyReaction reaction;

  @override
  ConsumerState<HomeIdentityHeader> createState() =>
      _HomeIdentityHeaderState();
}

class _HomeIdentityHeaderState extends ConsumerState<HomeIdentityHeader> {
  late final bool _showGreeting;

  @override
  void initState() {
    super.initState();
    _showGreeting = ref.read(buddyHomeSpeechAvailableProvider);
    if (_showGreeting) {
      Future<void>.microtask(
        () => ref.read(buddyHomeSpeechAvailableProvider.notifier).consume(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          key: const ValueKey('home-profile-opener'),
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline_rounded),
          tooltip: l10n.openProfileMenu,
        ),
        const SizedBox(width: RiksaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeGreeting(widget.name),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: RiksaSpacing.xs),
              BuddyCompanionInline(
                reaction: widget.reaction,
                speech: _showGreeting ? l10n.buddyHomeGreeting : null,
                size: 44,
              ),
            ],
          ),
        ),
        if (widget.streak > 0)
          Chip(
            avatar: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: Text(l10n.homeStreakDays(widget.streak)),
          ),
      ],
    );
  }
}

class HomeStudySection extends ConsumerWidget {
  const HomeStudySection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(learningHomeProvider).when(
      loading: () => const RiksaSkeleton(height: 210, radius: 24),
      error: (_, _) => RiksaStateView(
        icon: Icons.school_outlined,
        title: l10n.lessonLoadFailed,
        body: l10n.learningLoadErrorBody,
        actionLabel: l10n.tryAgain,
        onAction: () => ref.invalidate(learningHomeProvider),
      ),
      data: (data) {
        final subject = data.resumeSubject;
        final lesson = data.resumeLesson;
        if (subject == null || lesson == null) {
          return _HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeTodaysStudy, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: RiksaSpacing.sm),
                Text(l10n.homeStartHereBody),
                const SizedBox(height: RiksaSpacing.md),
                FilledButton(
                  key: const ValueKey('home-start-learning'),
                  onPressed: () => context.go('/learn'),
                  child: Text(l10n.homeStartHere),
                ),
              ],
            ),
          );
        }
        final progress = lesson.progress ?? subject.fraction;
        return _HomeCard(
          emphasized: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeTodaysStudy, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: RiksaSpacing.sm),
              Text(subject.category.name, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: RiksaSpacing.xs),
              Text(lesson.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (lesson.durationMinutes != null) ...[
                const SizedBox(height: RiksaSpacing.xs),
                Text(l10n.homeLessonMinutes(lesson.durationMinutes!)),
              ],
              const SizedBox(height: RiksaSpacing.md),
              LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
              const SizedBox(height: RiksaSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('home-continue-lesson'),
                  onPressed: () => context.push('/learn/resume'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(progress > 0 ? l10n.homeContinue : l10n.homeStartHere),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeProvinceSection extends ConsumerWidget {
  const HomeProvinceSection({super.key, required this.user});
  final AuthUser? user;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (user?.provinceId == null || user!.provinceId!.isEmpty) {
      return _HomeCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.homeProvinceSquad, style: Theme.of(context).textTheme.titleLarge),
          Text(l10n.homeProvinceMissing),
          TextButton(
            key: const ValueKey('home-select-province'),
            onPressed: () => context.push('/province-select'),
            child: Text(l10n.homeSelectProvince),
          ),
        ]),
      );
    }
    final rank = ref.watch(profileRankProvider);
    final board = ref.watch(leaderboardProvider(LeaderboardScope.province));
    final provinceOptions = ref.watch(provinceOptionsProvider).asData?.value;
    final province = provinceOptions
        ?.where((option) => option.id == user!.provinceId)
        .firstOrNull;
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final provinceName = province == null
        ? null
        : (isKhmer ? province.nameKhmer : province.nameLatin).trim();
    final squadTitle = provinceName?.isNotEmpty == true
        ? l10n.homeProvinceSquadNamed(provinceName!)
        : l10n.homeProvinceSquad;
    if (rank.isLoading || board.isLoading) {
      return const RiksaSkeleton(height: 170, radius: 24);
    }
    if (rank.hasError || board.hasError) {
      return _CompactRetry(
        title: squadTitle,
        onRetry: () {
          ref.invalidate(profileRankProvider);
          ref.invalidate(leaderboardProvider(LeaderboardScope.province));
        },
      );
    }
    final myRank = rank.value?.provinceRank;
    final rows = board.value ?? const <LeaderboardRow>[];
    final nearby = [...rows]..sort((a, b) => (a.rank - (myRank ?? 0)).abs().compareTo((b.rank - (myRank ?? 0)).abs()));
    return _HomeCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(squadTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        if (myRank != null && myRank > 0) Text(l10n.homeProvinceRank(myRank)),
        const SizedBox(height: RiksaSpacing.sm),
        for (final row in nearby.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(l10n.homeNearbyLearner(row.rank, row.userId == user!.id ? l10n.homeYou : row.fallbackName)),
          ),
        TextButton(
          key: const ValueKey('home-view-province-ranks'),
          onPressed: () => context.go('/leaderboard'),
          child: Text(l10n.homeViewProvinceRanks),
        ),
      ]),
    );
  }
}

class HomeCommunitiesSection extends ConsumerWidget {
  const HomeCommunitiesSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(socialFeedProvider);
    if (state is SocialFeedLoading) return const RiksaSkeleton(height: 190, radius: 24);
    if (state is SocialFeedFailure) {
      return _CompactRetry(title: l10n.homeFromCommunities, onRetry: () => ref.read(socialFeedProvider.notifier).load());
    }
    final loaded = state as SocialFeedLoaded;
    final joined = loaded.categories.where((category) => category.joined).map((category) => category.id).toSet();
    final posts = loaded.posts.where((post) => joined.contains(post.category.id)).take(2).toList();
    if (posts.isEmpty) return const SizedBox.shrink();
    return _HomeCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.homeFromCommunities, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        for (final post in posts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(post.title),
            subtitle: Text(l10n.homeCommunityPostMeta(post.category.name, post.author.displayName, post.commentCount)),
            onTap: () => context.push('/community/posts/${post.id}'),
          ),
        TextButton(
          key: const ValueKey('home-community-feed'),
          onPressed: () => context.go('/community'),
          child: Text(l10n.homeSeeCommunityFeed),
        ),
      ]),
    );
  }
}

class HomeUtilityRow extends StatelessWidget {
  const HomeUtilityRow({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      ActionChip(key: const ValueKey('home-communities'), avatar: const Icon(Icons.groups_outlined), label: Text(l10n.communitiesMenu), onPressed: () => context.push('/communities')),
      ActionChip(key: const ValueKey('home-saved-lessons'), avatar: const Icon(Icons.bookmark_outline), label: Text(l10n.menuSavedLessons), onPressed: () => context.push('/learn/saved')),
      ActionChip(key: const ValueKey('home-ai-tutor'), avatar: const Icon(Icons.auto_awesome_outlined), label: Text(l10n.aiTutor), onPressed: () => context.go('/ai')),
    ]);
  }
}

class _CompactRetry extends StatelessWidget {
  const _CompactRetry({required this.title, required this.onRetry});
  final String title;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _HomeCard(child: Row(children: [Expanded(child: Text(title)), IconButton(onPressed: onRetry, tooltip: AppLocalizations.of(context)!.tryAgain, icon: const Icon(Icons.refresh_rounded))]));
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.emphasized = false});
  final Widget child;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RiksaSpacing.md),
    decoration: BoxDecoration(
      color: emphasized ? context.riksa.brandSoft : context.riksa.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: emphasized ? context.riksa.brand : context.riksa.outline),
    ),
    child: child,
  );
}
