import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_chat_models.dart';

/// Device cache for one account's AI chat history.
///
/// A null user id represents a guest and deliberately has no chat cache.
class AiChatCache {
  AiChatCache([this.userId])
    : _userEpoch = userId == null ? null : _userCacheEpochs[userId] ?? 0;

  static const _legacySessionsKey = 'ai_chat_sessions_cache';
  static const _legacySessionPrefix = 'ai_chat_session_';
  static const _legacyCleanupKey = 'ai_chat_legacy_cache_cleared_v1';
  static const _sessionsKeyPrefix = 'ai_chat_sessions_cache_';
  static const _sessionKeyPrefix = 'ai_chat_session_';
  static Future<void> _cleanupQueue = Future<void>.value();
  static final Map<String, int> _userCacheEpochs = {};

  final String? userId;
  final int? _userEpoch;

  bool get _enabled =>
      userId != null &&
      userId!.isNotEmpty &&
      _userEpoch == (_userCacheEpochs[userId!] ?? 0);

  String? get _sessionsKey =>
      userId == null || userId!.isEmpty ? null : '$_sessionsKeyPrefix$userId';

  String? get _sessionPrefix =>
      userId == null || userId!.isEmpty ? null : '$_sessionKeyPrefix${userId}_';

  Future<void> saveSessions(List<AiChatSession> sessions) async {
    final key = _sessionsKey;
    if (key == null || !_enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await clearLegacyKeysOnce(prefs);
      if (!_enabled) return;
      final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(key, data);
      if (!_enabled) await prefs.remove(key);
    } catch (_) {
      // Cache write failures should never break the UI.
    }
  }

  Future<List<AiChatSession>> loadSessions() async {
    final key = _sessionsKey;
    if (key == null || !_enabled) return const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await clearLegacyKeysOnce(prefs);
      if (!_enabled) return const [];
      final data = prefs.getString(key);
      if (data == null || data.trim().isEmpty) return const [];
      final list = jsonDecode(data) as List?;
      if (list == null) return const [];
      final sessions = list
          .map(
            (item) =>
                AiChatSession.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList();
      return _enabled ? sessions : const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSession(AiChatSession session) async {
    final prefix = _sessionPrefix;
    if (prefix == null || !_enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await clearLegacyKeysOnce(prefs);
      if (!_enabled) return;
      final data = jsonEncode(session.toJson());
      final key = '$prefix${session.id}';
      await prefs.setString(key, data);
      if (!_enabled) await prefs.remove(key);
    } catch (_) {
      // Cache write failures should never break the UI.
    }
  }

  Future<AiChatSession?> loadSession(String id) async {
    final prefix = _sessionPrefix;
    if (prefix == null || !_enabled) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await clearLegacyKeysOnce(prefs);
      if (!_enabled) return null;
      final data = prefs.getString('$prefix$id');
      if (data == null || data.trim().isEmpty) return null;
      final map = jsonDecode(data) as Map?;
      if (map == null) return null;
      final session = AiChatSession.fromJson(map.cast<String, dynamic>());
      return _enabled ? session : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeSession(String id) async {
    final prefix = _sessionPrefix;
    if (prefix == null || !_enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await clearLegacyKeysOnce(prefs);
      if (!_enabled) return;
      await prefs.remove('$prefix$id');
      final current = await loadSessions();
      final updated = current.where((session) => session.id != id).toList();
      await saveSessions(updated);
    } catch (_) {
      // Cache removal failures should not crash.
    }
  }

  /// Removes the old device-wide cache when this version first touches it.
  static Future<void> clearLegacyKeysOnce([
    SharedPreferences? preferences,
  ]) async {
    final previous = _cleanupQueue;
    final completer = Completer<void>();
    _cleanupQueue = completer.future;
    await previous;
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (prefs.getBool(_legacyCleanupKey) == true) return;
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key == _legacySessionsKey || key.startsWith(_legacySessionPrefix)) {
          await prefs.remove(key);
        }
      }
      await prefs.setBool(_legacyCleanupKey, true);
    } catch (_) {
      // A later cache operation can retry the cleanup.
    } finally {
      completer.complete();
    }
  }

  /// Clears all of [userId]'s locally cached sessions after logout.
  static Future<void> clearForUser(String userId) async {
    if (userId.isEmpty) return;
    _userCacheEpochs[userId] = (_userCacheEpochs[userId] ?? 0) + 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionPrefix = '$_sessionKeyPrefix${userId}_';
      final sessionsKey = '$_sessionsKeyPrefix$userId';
      for (final key in prefs.getKeys()) {
        if (key == sessionsKey || key.startsWith(sessionPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {
      // Logout must complete even when its optional cache cannot be cleared.
    }
  }
}
