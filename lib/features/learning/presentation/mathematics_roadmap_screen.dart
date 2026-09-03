import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';

/// Minimal roadmap backed entirely by the category roadmap API.
class LearningRoadmapScreen extends ConsumerWidget {
  const LearningRoadmapScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmap = ref.watch(learningRoadmapProvider(categoryId));
    return Scaffold(
      appBar: AppBar(title: const Text('Mathematics roadmap')),
      body: roadmap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(learningRoadmapProvider(categoryId)),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(learningRoadmapProvider(categoryId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: data.lessons.length + 1,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 18)
                : const Padding(
                    padding: EdgeInsets.only(left: 22),
                    child: SizedBox(height: 18, child: VerticalDivider()),
                  ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(data.categoryName,
                    style: Theme.of(context).textTheme.headlineMedium);
              }
              final lesson = data.lessons[index - 1];
              return _RoadmapLessonTile(
                lesson: lesson,
                onTap: lesson.state == LessonProgressState.locked
                    ? null
                    : () => context.push('/learn/${lesson.id}', extra: lesson),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoadmapLessonTile extends StatelessWidget {
  const _RoadmapLessonTile({required this.lesson, this.onTap});

  final LessonSummary lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final completed = lesson.state == LessonProgressState.completed;
    final available = lesson.state == LessonProgressState.available;
    final color = completed
        ? context.riksa.jade
        : available
        ? context.riksa.math
        : context.riksa.inkFaint;
    final icon = completed
        ? Icons.check_circle_rounded
        : available
        ? Icons.play_circle_fill_rounded
        : Icons.lock_outline_rounded;
    return Material(
      color: context.riksa.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('roadmap-lesson-${lesson.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${lesson.position}. ${lesson.title}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: onTap == null ? context.riksa.inkMuted : null,
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 4),
                    Text(
                      available ? 'Available' : completed ? 'Completed' : 'Locked',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                    Text('${lesson.exerciseCount} exercises · +${lesson.baseXp} XP',
                        style: TextStyle(color: context.riksa.inkMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (available || completed) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
