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
    this.totalExercises,
  });

  final int xpEarned;
  final String? roadmapCategoryId;
  final String? lessonTitle;
  final String? categoryName;
  final int? totalExercises;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
    final insight = resolveInsightForCategory(categoryName);
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

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
                    isKhmer ? 'បានបញ្ចប់មេរៀនជោគជ័យ!' : 'Lesson Mastered!',
                    textAlign: TextAlign.center,
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

                  const SizedBox(height: RiksaSpacing.md),

                  // Achievement Badges Row
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: RiksaSpacing.sm,
                    runSpacing: RiksaSpacing.xs,
                    children: [
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
                              isKhmer
                                  ? '+$xpEarned ពិន្ទុ XP ទទួលបាន'
                                  : '+$xpEarned XP Earned',
                              style: TextStyle(
                                color: riksa.saffron,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Exercises Completed Pill
                      if (totalExercises != null && totalExercises! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RiksaSpacing.md,
                            vertical: RiksaSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: riksa.jade.withValues(alpha: 0.15),
                            borderRadius: AppRadii.fullBorder,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: riksa.jade,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isKhmer
                                    ? '$totalExercises លំហាត់បានអនុវត្ត'
                                    : '$totalExercises ${totalExercises == 1 ? "Exercise" : "Exercises"} Completed',
                                style: TextStyle(
                                  color: riksa.jade,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                      key: const ValueKey('lesson-completion-share'),
                      onPressed: () {
                        context.push('/community/create');
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        isKhmer
                            ? 'ចែករំលែកទៅកាន់សហគមន៍'
                            : 'Share Achievement to Community',
                      ),
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.sm),

                  // Primary Navigation Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('lesson-completion-continue'),
                      onPressed: () => context.go(
                        roadmapCategoryId == null
                            ? '/learn'
                            : '/learn/roadmap/$roadmapCategoryId',
                      ),
                      icon: const Icon(Icons.school_rounded, size: 19),
                      label: Text(
                        roadmapCategoryId == null
                            ? (isKhmer ? 'បន្តការរៀន' : 'Continue learning')
                            : (isKhmer ? 'ត្រឡប់ទៅផែនទីសិក្សា' : 'Back to roadmap'),
                      ),
                    ),
                  ),

                  const SizedBox(height: RiksaSpacing.xs),

                  TextButton(
                    key: const ValueKey('lesson-completion-home'),
                    onPressed: () => context.go('/home'),
                    child: Text(isKhmer ? 'ត្រឡប់ទៅទំព័រដើម' : 'Back home'),
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
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final state = ref.watch(lessonCatalogProvider);
    final active = state.lessons
        .where((lesson) => !lesson.completed && (lesson.progress ?? 0) > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(isKhmer ? 'បន្តការរៀន' : 'Resume learning'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : active.isEmpty
          ? IllustratedEmptyState(
              title: isKhmer ? 'មិនមានមេរៀនកំពុងរៀនទេ' : 'No lesson in progress',
              body: isKhmer
                  ? 'ជ្រើសរើសមេរៀនដើម្បីចាប់ផ្តើមការសិក្សាជាបន្ត។'
                  : 'Choose a lesson to begin your next learning streak.',
              actionLabel: isKhmer ? 'រុករកមេរៀន' : 'Browse lessons',
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
