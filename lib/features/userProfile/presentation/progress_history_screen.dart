import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_glass.dart';
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
          // His glass tab strip, driven by the same DefaultTabController.
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: _ProgressSectionTabs(),
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
                      leading: const _PixelXpBadge(),
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

class _PixelXpBadge extends StatelessWidget {
  const _PixelXpBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: palette.brandSoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: 25,
          child: CustomPaint(
            painter: _PixelXpPainter(
              color: palette.brand,
              accent: palette.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelXpPainter extends CustomPainter {
  const _PixelXpPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final outline = Paint()
      ..color = Color.lerp(color, Colors.black, .26)!
      ..style = PaintingStyle.fill;
    final main = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .52)
      ..style = PaintingStyle.fill;
    final spark = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    void px(Paint paint, int x, int y, [int w = 1, int h = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    px(outline, 7, 1, 5, 1);
    px(outline, 6, 2, 5, 2);
    px(outline, 5, 4, 5, 2);
    px(outline, 4, 6, 6, 2);
    px(outline, 7, 8, 5, 2);
    px(outline, 6, 10, 4, 2);
    px(outline, 5, 12, 3, 2);

    px(main, 7, 2, 3, 2);
    px(main, 6, 4, 3, 2);
    px(main, 5, 6, 4, 1);
    px(main, 6, 7, 3, 1);
    px(main, 8, 8, 3, 1);
    px(main, 7, 9, 3, 2);
    px(main, 6, 11, 2, 2);
    px(main, 5, 13, 2, 1);

    px(shine, 8, 2, 1, 2);
    px(shine, 7, 4, 1, 1);
    px(spark, 2, 3, 1, 1);
    px(spark, 13, 4, 1, 1);
    px(spark, 12, 12, 2, 1);
  }

  @override
  bool shouldRepaint(covariant _PixelXpPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
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

class _ProgressSectionTabs extends StatefulWidget {
  const _ProgressSectionTabs();

  @override
  State<_ProgressSectionTabs> createState() => _ProgressSectionTabsState();
}

class _ProgressSectionTabsState extends State<_ProgressSectionTabs> {
  late TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DefaultTabController.of(context);
    _controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    Widget tab(String label, int index) {
      final isSelected = _controller.index == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _controller.animateTo(index);
            },
            borderRadius: AppRadii.fullBorder,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  label,
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? palette.brand : palette.inkMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 46,
        child: RiksaGlassSurface(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2;
              final showingRank = _controller.index == 1;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    start: showingRank ? tabWidth : 0,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: const RiksaGlassSelection(),
                  ),
                  Row(
                    children: [
                      tab('XP activity', 0),
                      tab('Rank changes', 1),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
