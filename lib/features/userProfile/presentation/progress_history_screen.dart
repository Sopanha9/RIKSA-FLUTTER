import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/profile_provider.dart';

/// Names an XP source in the learner's language.
///
/// The backend sends screaming snake case (`LESSON`, `STREAK_BONUS`). Showing
/// that raw, even tidied up, leaves English inside a Khmer screen, so known
/// values are mapped and anything new falls back to a readable form of the
/// code rather than an empty row.
String xpSourceLabel(AppLocalizations l10n, String sourceType) =>
    switch (sourceType.toUpperCase()) {
      'LESSON' || 'LESSON_COMPLETE' => l10n.xpSourceLesson,
      'EXERCISE' || 'EXERCISE_CORRECT' => l10n.xpSourceExercise,
      'ACHIEVEMENT' => l10n.xpSourceAchievement,
      'STREAK' || 'STREAK_BONUS' => l10n.xpSourceStreak,
      'XP_REWARD' || 'REWARD' => l10n.xpSourceReward,
      _ =>
        sourceType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' '),
    };

/// Names a leaderboard scope in the learner's language.
String rankScopeLabel(AppLocalizations l10n, String scope) =>
    switch (scope.toUpperCase()) {
      'PROVINCE' => l10n.leaderboardProvince,
      'COUNTRY' || 'GLOBAL' || 'NATIONAL' => l10n.leaderboardNational,
      _ => scope.replaceAll('_', ' '),
    };

class ProgressHistoryScreen extends ConsumerWidget {
  const ProgressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.progressHistoryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.progressHistoryXpTab),
              Tab(text: l10n.progressHistoryRankTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _XpHistory(ref: ref),
            _RankHistory(ref: ref),
          ],
        ),
      ),
    );
  }
}

/// A failure the learner can act on, rather than a sentence they can only read.
class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IllustratedEmptyState(
      key: const ValueKey('progress-history-error'),
      title: message,
      body: l10n.loadFailedCheckConnection,
      actionLabel: l10n.tryAgain,
      onAction: onRetry,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.loading,
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _XpHistory extends StatelessWidget {
  const _XpHistory({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(profileDashboardProvider)
        .when(
          loading: () => const _Loading(),
          error: (_, _) => _HistoryError(
            message: l10n.progressHistoryXpFailed,
            onRetry: () => ref.invalidate(profileDashboardProvider),
          ),
          data: (data) => data.activities.isEmpty
              ? IllustratedEmptyState(
                  title: l10n.progressHistoryXpEmptyTitle,
                  body: l10n.progressHistoryXpEmptyBody,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: data.activities.length,
                  itemBuilder: (context, i) {
                    final item = data.activities[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.bolt_rounded),
                      ),
                      title: Text(xpSourceLabel(l10n, item.sourceType)),
                      subtitle: Text(
                        item.createdAt == null
                            ? ''
                            : DateFormat.yMMMd(
                                Localizations.localeOf(context).toString(),
                              ).add_jm().format(item.createdAt!.toLocal()),
                      ),
                      trailing: Text(l10n.xpAmount(item.amount)),
                    );
                  },
                ),
        );
  }
}

class _RankHistory extends StatelessWidget {
  const _RankHistory({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(rankHistoryProvider)
        .when(
          loading: () => const _Loading(),
          error: (_, _) => _HistoryError(
            message: l10n.progressHistoryRankFailed,
            onRetry: () => ref.invalidate(rankHistoryProvider),
          ),
          data: (items) => items.isEmpty
              ? IllustratedEmptyState(
                  title: l10n.progressHistoryRankEmptyTitle,
                  body: l10n.progressHistoryRankEmptyBody,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final improved = item.newRank < item.oldRank;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          improved ? Icons.trending_up : Icons.trending_down,
                        ),
                      ),
                      title: Text(
                        l10n.progressHistoryRankRow(
                          rankScopeLabel(l10n, item.scope),
                        ),
                      ),
                      subtitle: Text(
                        item.changedAt == null
                            ? ''
                            : DateFormat.yMMMd(
                                Localizations.localeOf(context).toString(),
                              ).format(item.changedAt!.toLocal()),
                      ),
                      trailing: Text('#${item.oldRank} → #${item.newRank}'),
                    );
                  },
                ),
        );
  }
}
