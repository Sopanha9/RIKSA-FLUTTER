import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../providers/lesson_catalog_provider.dart';
import 'widgets/learning_insights.dart';

class LessonCompletionScreen extends StatelessWidget {
  const LessonCompletionScreen({
    super.key,
    required this.xpEarned,
    this.roadmapCategoryId,
    this.lessonTitle,
    this.categoryName,
  });

  final int xpEarned;
  final String? roadmapCategoryId;
  final String? lessonTitle;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
    final insight = resolveInsightForCategory(categoryName);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            RiksaSpacing.lg,
            RiksaSpacing.xl,
            RiksaSpacing.lg,
            RiksaSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: RiksaSpacing.sm),
                  // Celebration Badge
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: riksa.saffronSoft,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: riksa.saffron.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 56,
                      color: riksa.saffron,
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.md),

                  Text(
                    'Lesson Mastered!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: RiksaSpacing.xs),

                  if (lessonTitle != null && lessonTitle!.isNotEmpty)
                    Text(
                      lessonTitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: riksa.inkMuted,
                          ),
                    ),

                  const SizedBox(height: RiksaSpacing.sm),

                  // XP Reward Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RiksaSpacing.md,
                      vertical: RiksaSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: riksa.saffron.withValues(alpha: 0.15),
                      borderRadius: AppRadii.fullBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20, color: riksa.saffron),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpEarned XP Earned',
                          style: TextStyle(
                            color: riksa.saffron,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.lg),

                  // Micro-Insight Card (Cultural / Academic Wisdom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(RiksaSpacing.md),
                    decoration: BoxDecoration(
                      color: riksa.surfaceRaised,
                      borderRadius: AppRadii.largeBorder,
                      border: Border.all(
                        color: riksa.jade.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: riksa.jade.withValues(alpha: 0.12),
                                borderRadius: AppRadii.smallBorder,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    size: 14,
                                    color: riksa.jade,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    insight.tag,
                                    style: TextStyle(
                                      color: riksa.jade,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RiksaSpacing.xs),
                        Text(
                          insight.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.body,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: riksa.inkMuted,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: RiksaSpacing.xs),
                        Text(
                          '💡 ${insight.takeaway}',
                          style: TextStyle(
                            color: riksa.jadeStrong,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.lg),

                  // Share to Community Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/community/create');
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Achievement to Community'),
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.sm),

                  // Primary Navigation Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(
                        roadmapCategoryId == null
                            ? '/learn'
                            : '/learn/roadmap/$roadmapCategoryId',
                      ),
                      icon: const Icon(Icons.school_rounded, size: 19),
                      label: Text(
                        roadmapCategoryId == null
                            ? 'Continue learning'
                            : 'Back to roadmap',
                      ),
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.xs),

                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResumeLearningScreen extends ConsumerWidget {
  const ResumeLearningScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonCatalogProvider);
    final active = state.lessons
        .where((lesson) => !lesson.completed && (lesson.progress ?? 0) > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Resume learning')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : active.isEmpty
          ? IllustratedEmptyState(
              title: 'No lesson in progress',
              body: 'Choose a lesson to begin your next learning streak.',
              actionLabel: 'Browse lessons',
              onAction: () => context.go('/learn'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = active[index];
                return RiksaPastelCard(
                  onTap: () =>
                      context.push('/learn/${lesson.id}', extra: lesson),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: lesson.progress),
                      const SizedBox(height: 6),
                      Text(
                        '${((lesson.progress ?? 0) * 100).round()}% complete',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
