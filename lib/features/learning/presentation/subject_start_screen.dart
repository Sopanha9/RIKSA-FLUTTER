import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/learning_home_provider.dart';
import 'learning_design.dart';
import 'subject_roadmap_screen.dart';
import 'widgets/learning_status_bar.dart';

/// Opens the roadmap for a subject named by its onboarding id, such as
/// `MATHEMATICS`.
///
/// Setup ends here so a learner who picked Math lands on the Math path rather
/// than being asked to pick a subject a second time. Category ids come from
/// the learning API, so the subject is resolved once the subjects load. When it
/// cannot be matched, the learner falls back to the learning home.
class SubjectStartScreen extends ConsumerWidget {
  const SubjectStartScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(learningHomeProvider);
    final expected = stemSubjectForId(subjectId);
    final match = home.asData?.value.subjects
        .where((subject) => subject.subject == expected)
        .firstOrNull;

    if (match != null) {
      return LearningRoadmapScreen(categoryId: match.category.id);
    }
    if (!home.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/learn');
      });
    }
    return Scaffold(
      backgroundColor: context.riksa.canvas,
      appBar: const LearningStatusBar(),
      body: Center(
        child: CircularProgressIndicator(color: learningAnchor(context)),
      ),
    );
  }
}
