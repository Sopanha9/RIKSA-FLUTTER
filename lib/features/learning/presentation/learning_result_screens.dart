import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/riksa_components.dart';
import '../providers/lesson_catalog_provider.dart';

class LessonCompletionScreen extends StatelessWidget {
  const LessonCompletionScreen({super.key, required this.xpEarned});
  final int xpEarned;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 96,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              Text(
                'Lesson completed!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'You earned $xpEarned XP. Your roadmap and streak are up to date.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/learn'),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Continue roadmap'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
