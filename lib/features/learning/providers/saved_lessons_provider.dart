import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists bookmarked lesson IDs locally on device.
class SavedLessonsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'riksa_saved_lesson_ids';
  Completer<void>? _restoreCompleter;

  Future<void> get restored => (_restoreCompleter ??= Completer<void>()).future;

  @override
  Set<String> build() {
    _restoreCompleter = Completer<void>();
    _restore().ignore();
    return const {};
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final list = preferences.getStringList(_storageKey);
      if (list != null && list.isNotEmpty) {
        state = list.toSet();
      }
      _restoreCompleter?.complete();
    } catch (error, stackTrace) {
      _restoreCompleter?.completeError(error, stackTrace);
    }
  }

  Future<void> toggle(String lessonId) async {
    final next = Set<String>.from(state);
    if (next.contains(lessonId)) {
      next.remove(lessonId);
    } else {
      next.add(lessonId);
    }
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, next.toList());
  }

  Future<void> add(String lessonId) async {
    if (state.contains(lessonId)) return;
    final next = Set<String>.from(state)..add(lessonId);
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, next.toList());
  }

  Future<void> remove(String lessonId) async {
    if (!state.contains(lessonId)) return;
    final next = Set<String>.from(state)..remove(lessonId);
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, next.toList());
  }

  bool isSaved(String lessonId) => state.contains(lessonId);
}

final savedLessonsProvider =
    NotifierProvider<SavedLessonsNotifier, Set<String>>(
      SavedLessonsNotifier.new,
    );

/// Completes after persisted bookmark IDs have been read at least once.
///
/// Keeping this separate from the synchronous set avoids an empty-state flash
/// without making every bookmark read asynchronous.
final savedLessonsRestoredProvider = FutureProvider<void>((ref) {
  ref.watch(savedLessonsProvider);
  return ref.read(savedLessonsProvider.notifier).restored;
});
