import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';

const defaultProfileCoverId = 'jade';

class ProfileCoverNotifier extends Notifier<String> {
  String? _userId;
  String _coverId = defaultProfileCoverId;
  int _selectionVersion = 0;

  @override
  String build() {
    final auth = ref.watch(authProvider);
    final userId = auth is Authenticated ? auth.user.id : null;
    if (_userId != userId) {
      _selectionVersion++;
      _coverId = defaultProfileCoverId;
    }
    _userId = userId;
    unawaited(_restore(userId, _selectionVersion));
    return _coverId;
  }

  Future<void> _restore(String? userId, int version) async {
    if (userId == null || userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key(userId));
    if (_userId == userId &&
        _selectionVersion == version &&
        saved != null &&
        saved.isNotEmpty) {
      _coverId = saved;
      state = saved;
    }
  }

  Future<void> select(String coverId) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    _selectionVersion++;
    _coverId = coverId;
    state = coverId;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(userId), coverId);
  }

  String _key(String userId) => 'riksa_profile_cover_$userId';
}

final profileCoverProvider = NotifierProvider<ProfileCoverNotifier, String>(
  ProfileCoverNotifier.new,
);
