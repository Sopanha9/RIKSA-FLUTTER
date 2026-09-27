import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/current_user_provider.dart';

/// Manages and persists bookmarked lesson IDs locally, separately per account.
class SavedLessonsNotifier extends Notifier<Set<String>> {
  static const _legacyStorageKey = 'riksa_saved_lesson_ids';
  static const _storageKeyPrefix = 'riksa_saved_lesson_ids_';
  static const _guestStorageKey = 'riksa_saved_lesson_ids_guest';

  Completer<void>? _restoreCompleter;
  String? _userId;
  int _restoreVersion = 0;

  Future<void> get restored => (_restoreCompleter ??= Completer<void>()).future;

  @override
  Set<String> build() {
    final userId = watchCurrentUserId(ref);
    _userId = userId;
    final version = ++_restoreVersion;
    final previousRestore = _restoreCompleter;
    if (previousRestore != null && !previousRestore.isCompleted) {
      previousRestore.complete();
    }
    final completer = _restoreCompleter = Completer<void>();
    _restore(userId, version, completer).ignore();
    return const {};
  }

  Future<void> _restore(
    String? userId,
    int version,
    Completer<void> completer,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final legacy = preferences.getStringList(_legacyStorageKey);
      if (legacy != null) {
        if (preferences.getStringList(_guestStorageKey) == null) {
          await preferences.setStringList(_guestStorageKey, legacy);
        }
        await preferences.remove(_legacyStorageKey);
      }

      final list = preferences.getStringList(_keyFor(userId));
      if (version == _restoreVersion && _userId == userId && ref.mounted) {
        state = list == null ? const {} : list.toSet();
      }
    } catch (_) {
      // Bookmarks remain usable in memory when device storage is unavailable.
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<void> toggle(String lessonId) async {
    await _waitForRestore();
    final userId = _userId;
    final key = _keyFor(userId);
    final next = Set<String>.from(state);
    if (next.contains(lessonId)) {
      next.remove(lessonId);
    } else {
      next.add(lessonId);
    }
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(key, next.toList());
  }

  Future<void> add(String lessonId) async {
    await _waitForRestore();
    final userId = _userId;
    if (state.contains(lessonId)) return;
    final key = _keyFor(userId);
    final next = Set<String>.from(state)..add(lessonId);
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(key, next.toList());
  }

  Future<void> remove(String lessonId) async {
    await _waitForRestore();
    final userId = _userId;
    if (!state.contains(lessonId)) return;
    final key = _keyFor(userId);
    final next = Set<String>.from(state)..remove(lessonId);
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(key, next.toList());
  }

  String _keyFor(String? userId) => userId == null || userId.isEmpty
      ? _guestStorageKey
      : '$_storageKeyPrefix$userId';

  Future<void> _waitForRestore() async {
    while (true) {
      final userId = _userId;
      final completer = _restoreCompleter;
      if (completer == null) return;
      await completer.future;
      if (userId == _userId && identical(completer, _restoreCompleter)) {
        return;
      }
    }
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
///
/// It rebuilds per account, not per bookmark change: watching the set itself
/// would invalidate this future when the restore writes its own result.
final savedLessonsRestoredProvider = FutureProvider<void>((ref) {
  watchCurrentUserId(ref);
  // Reading the state first makes the notifier rebuild for a new account
  // before its restore future is taken.
  ref.read(savedLessonsProvider);
  return ref.read(savedLessonsProvider.notifier).restored;
});
