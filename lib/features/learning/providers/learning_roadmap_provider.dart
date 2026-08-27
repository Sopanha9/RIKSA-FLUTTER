import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_models.dart';
import 'lesson_catalog_provider.dart';

final learningRoadmapProvider = FutureProvider.autoDispose
    .family<LearningRoadmap, String>((ref, categoryId) {
      return ref.watch(learningApiProvider).roadmap(categoryId);
    });

final lessonDetailProvider = FutureProvider.autoDispose
    .family<LessonDetail, String>((ref, lessonId) {
      return ref.watch(learningApiProvider).lesson(lessonId);
    });
