import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/buddy_care.dart';
import '../../domain/mascot.dart';
import '../../providers/buddy_care_provider.dart';
import '../../providers/mascot_provider.dart';
import 'mascot_face.dart';
import 'mascot_scene.dart';
import 'mascot_view.dart';

/// Compact study-first summary of the learner's care for their buddy today.
class BuddyCareCard extends ConsumerStatefulWidget {
  const BuddyCareCard({super.key});

  @override
  ConsumerState<BuddyCareCard> createState() => _BuddyCareCardState();
}

class _BuddyCareCardState extends ConsumerState<BuddyCareCard> {
  late final MascotController _mascot = MascotController(MascotMood.idle);
  BuddyVitality? _lastVitality;
  Timer? _initialHappyTimer;

  @override
  void dispose() {
    _initialHappyTimer?.cancel();
    _mascot.dispose();
    super.dispose();
  }

  void _syncMood(BuddyVitality vitality) {
    final previous = _lastVitality;
    if (previous == vitality) return;
    _lastVitality = vitality;
    _initialHappyTimer?.cancel();
    if (vitality == BuddyVitality.lively) {
      _mascot.mood = MascotMood.idle;
      _mascot.react(MascotMood.happy);
      _initialHappyTimer = Timer(
        MascotSprites.loopDuration(MascotMood.happy),
        () {
          if (mounted && _lastVitality == BuddyVitality.lively) {
            _mascot.mood = MascotMood.idle;
          }
        },
      );
    } else {
      _mascot.mood = moodFor(vitality);
    }
  }

  int _count(BuddyCareState care, BuddyCareSource source) {
    final serverRow = care.today
        .where((item) => item.key.toUpperCase() == source.key)
        .firstOrNull;
    return serverRow?.count ?? care.care.countFor(source, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final care = ref.watch(buddyCareProvider);
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? care.species;
    final name = profile?.name ?? (care.name.isEmpty ? 'Croco' : care.name);
    final vitality = care.care.vitality;
    _syncMood(vitality);
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final headerExtra = ((textScale - 1.5) * 28).clamp(0, 72).toDouble();
    final scene = MascotScenes.asset(
      species,
      Theme.of(context).brightness,
      party: care.care.bondLevel >= 4,
    );

    return Card(
      key: const ValueKey('buddy-care-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 82 + headerExtra,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  scene,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.medium,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        palette.canvas.withValues(alpha: .94),
                        palette.canvas.withValues(alpha: .72),
                        palette.canvas.withValues(alpha: .08),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    top: 8,
                    bottom: 8,
                    end: 88,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.buddyCareTitle(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        switch (vitality) {
                          BuddyVitality.lively => l10n.buddyEnergyLively(name),
                          BuddyVitality.steady => l10n.buddyEnergySteady(name),
                          BuddyVitality.sleepy => l10n.buddyEnergySleepy(name),
                          BuddyVitality.napping => l10n.buddyEnergyNapping(
                            name,
                          ),
                        },
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          key: const ValueKey('buddy-energy-bar'),
                          minHeight: 4,
                          value: care.care.energy / 100,
                          color: palette.saffron,
                          backgroundColor: palette.ink.withValues(alpha: .12),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Semantics(
                      button: true,
                      label: l10n.buddyCareTitle(name),
                      onLongPressHint: l10n.buddyChooseAction,
                      child: GestureDetector(
                        onTap: () => _mascot.react(
                          care.care.bondLevel >= 3
                              ? MascotMood.love
                              : MascotMood.happy,
                        ),
                        onLongPress: () => context.push('/mascot-select'),
                        child: MascotView(
                          species: species,
                          controller: _mascot,
                          size: 58,
                          alive: vitality != BuddyVitality.napping,
                          semanticLabel: name,
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 58,
                  bottom: 6,
                  child: ExcludeSemantics(
                    child: MascotFaceAvatar(
                      face: faceFor(vitality),
                      size: 24,
                      loops: 0,
                      background: palette.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CareRow(
                  icon: Icons.menu_book_rounded,
                  label: l10n.buddyCareLesson,
                  count: _count(care, BuddyCareSource.lesson),
                  done: _count(care, BuddyCareSource.lesson) > 0,
                ),
                _CareRow(
                  icon: Icons.auto_stories_rounded,
                  label: l10n.buddyCareRead,
                  count: _count(
                    care,
                    BuddyCareSource.blogRead,
                  ).clamp(0, 1).toInt(),
                  done: _count(care, BuddyCareSource.blogRead) > 0,
                ),
                _CareRow(
                  icon: Icons.forum_outlined,
                  label: l10n.buddyCareShare,
                  count: _count(care, BuddyCareSource.post),
                  done: _count(care, BuddyCareSource.post) > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.done,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 22),
      child: Row(
        children: [
          Icon(icon, size: 15, color: palette.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: MascotFaceAvatar(
                    face: MascotFace.happy,
                    size: 18,
                    loops: 0,
                    background: palette.surface,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.check_rounded, size: 16, color: palette.brand),
              ],
            )
          else
            Text(
              '$count/1',
              semanticsLabel: l10n.buddyCareProgress(count),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}
