import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_chat_models.dart';

class AiChatCache {
  static const _sessionsKey = 'ai_chat_sessions_cache';
  static const _sessionPrefix = 'ai_chat_session_';

  Future<void> saveSessions(List<AiChatSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, data);
    } catch (_) {
      // Cache write failures should never break the UI
    }
  }

  Future<List<AiChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_sessionsKey);
      if (data == null || data.trim().isEmpty) return const [];
      final list = jsonDecode(data) as List?;
      if (list == null) return const [];
      return list
          .map((item) => AiChatSession.fromJson((item as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSession(AiChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(session.toJson());
      await prefs.setString('$_sessionPrefix${session.id}', data);
    } catch (_) {
      // Cache write failures should never break the UI
    }
  }

  Future<AiChatSession?> loadSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_sessionPrefix$id');
      if (data == null || data.trim().isEmpty) return null;
      final map = jsonDecode(data) as Map?;
      if (map == null) return null;
      return AiChatSession.fromJson(map.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> removeSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_sessionPrefix$id');
      final current = await loadSessions();
      final updated = current.where((s) => s.id != id).toList();
      await saveSessions(updated);
    } catch (_) {
      // Cache removal failures should not crash
    }
  }
}
