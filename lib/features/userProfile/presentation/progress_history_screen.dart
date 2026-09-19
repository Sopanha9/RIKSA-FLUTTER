import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../providers/profile_provider.dart';

class ProgressHistoryScreen extends ConsumerWidget {
  const ProgressHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Progress history'),
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

class _XpHistory extends StatelessWidget {
  const _XpHistory({required this.ref});
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) => ref
      .watch(profileDashboardProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load XP history.')),
        data: (data) => data.activities.isEmpty
            ? const IllustratedEmptyState(
                title: 'No XP yet',
                body: 'Complete a lesson to start your history.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: data.activities.length,
                itemBuilder: (context, i) {
                  final item = data.activities[i];
                  return ListTile(
                    leading: const _PixelXpBadge(),
                    title: Text(item.sourceType.replaceAll('_', ' ')),
                    subtitle: Text(
                      item.createdAt == null
                          ? ''
                          : DateFormat.yMMMd().add_jm().format(
                              item.createdAt!.toLocal(),
                            ),
                    ),
                    trailing: Text('+${item.amount} XP'),
                  );
                },
              ),
      );
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
  Widget build(BuildContext context) => ref
      .watch(rankHistoryProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load rank history.')),
        data: (items) => items.isEmpty
            ? const IllustratedEmptyState(
                title: 'No rank changes yet',
                body: 'Keep earning XP to move up the leaderboard.',
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
                    title: Text('${item.scope} rank'),
                    subtitle: Text(
                      item.changedAt == null
                          ? ''
                          : DateFormat.yMMMd().format(
                              item.changedAt!.toLocal(),
                            ),
                    ),
                    trailing: Text('#${item.oldRank} → #${item.newRank}'),
                  );
                },
              ),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    final selectedFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.54);
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.fullBorder,
          boxShadow: [
            BoxShadow(
              color: palette.ink.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadii.fullBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: AppRadii.fullBorder,
                border: Border.all(color: glassBorder),
              ),
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selectedFill,
                            borderRadius: AppRadii.fullBorder,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.36),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.ink.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
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
        ),
      ),
    );
  }
}
