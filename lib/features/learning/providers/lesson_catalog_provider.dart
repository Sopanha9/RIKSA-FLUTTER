import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/learning_api.dart';
import '../data/learning_models.dart';

final learningApiProvider = Provider<LearningApi>((ref) {
  return LearningApi(ref.watch(dioClientProvider));
});

class LessonCatalogState {
  const LessonCatalogState({
    this.lessons = const [],
    this.categories = const [],
    this.selectedGrade,
    this.selectedCategoryId,
    this.selectedDifficulty,
    this.page = 0,
    this.totalPages = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<LessonSummary> lessons;
  final List<LearningCategory> categories;
  final int? selectedGrade;
  final String? selectedCategoryId;
  final LessonDifficulty? selectedDifficulty;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => page + 1 < totalPages;
  bool get hasGradeData => lessons.any((lesson) => lesson.grade != null);

  LessonCatalogState copyWith({
    List<LessonSummary>? lessons,
    List<LearningCategory>? categories,
    int? selectedGrade,
    bool clearGrade = false,
    String? selectedCategoryId,
    bool clearCategory = false,
    LessonDifficulty? selectedDifficulty,
    bool clearDifficulty = false,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => LessonCatalogState(
    lessons: lessons ?? this.lessons,
    categories: categories ?? this.categories,
    selectedGrade: clearGrade ? null : selectedGrade ?? this.selectedGrade,
    selectedCategoryId: clearCategory
        ? null
        : selectedCategoryId ?? this.selectedCategoryId,
    selectedDifficulty: clearDifficulty
        ? null
        : selectedDifficulty ?? this.selectedDifficulty,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class LessonCatalogNotifier extends Notifier<LessonCatalogState> {
  static const _pageSize = 20;

  @override
  LessonCatalogState build() {
    // Notifier state is not initialized until build returns. Defer the first
    // load so load() can safely read and update state.
    unawaited(Future<void>.microtask(load));
    return const LessonCatalogState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(learningApiProvider);
      final results = await Future.wait<Object>([
        api.listLessons(
          categoryId: state.selectedCategoryId,
          difficulty: state.selectedDifficulty,
          grade: state.selectedGrade,
          size: _pageSize,
        ),
        if (state.categories.isEmpty)
          api.categories()
        else
          Future<List<LearningCategory>>.value(state.categories),
      ]);
      final page = results[0] as LessonPage;
      final stemLessons = page.content
          .where((lesson) => isStemLearningCategory(lesson.categoryName))
          .toList(growable: false);
      final stemCategories = (results[1] as List<LearningCategory>)
          .where((category) => isStemLearningCategory(category.name))
          .toList(growable: false);
      state = state.copyWith(
        lessons: stemLessons,
        categories: stemCategories,
        page: page.page,
        totalPages: page.totalPages,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> selectGrade(int? grade) async {
    state = state.copyWith(selectedGrade: grade, clearGrade: grade == null);
    await load();
  }

  Future<void> selectCategory(String? categoryId) async {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
    await load();
  }

  Future<void> selectDifficulty(LessonDifficulty? difficulty) async {
    state = state.copyWith(
      selectedDifficulty: difficulty,
      clearDifficulty: difficulty == null,
    );
    await load();
  }

  /// Applies the bottom-sheet selection atomically, resulting in one reload.
  Future<void> applyFilters({
    int? grade,
    String? categoryId,
    LessonDifficulty? difficulty,
  }) async {
    state = state.copyWith(
      selectedGrade: grade,
      clearGrade: grade == null,
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      selectedDifficulty: difficulty,
      clearDifficulty: difficulty == null,
    );
    await load();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final snapshot = state;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(learningApiProvider)
          .listLessons(
            categoryId: snapshot.selectedCategoryId,
            difficulty: snapshot.selectedDifficulty,
            grade: snapshot.selectedGrade,
            page: snapshot.page + 1,
            size: _pageSize,
          );
      state = state.copyWith(
        lessons: [
          ...snapshot.lessons,
          ...page.content.where(
            (lesson) => isStemLearningCategory(lesson.categoryName),
          ),
        ],
        page: page.page,
        totalPages: page.totalPages,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  String _message(Object error) {
    if (error is DioException) return dioErrorMessage(error);
    return 'Something went wrong';
  }
}

final lessonCatalogProvider =
    NotifierProvider<LessonCatalogNotifier, LessonCatalogState>(
      LessonCatalogNotifier.new,
    );
