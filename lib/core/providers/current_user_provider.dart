import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';

String? _userIdOf(AuthState auth) =>
    auth is Authenticated ? auth.user.id : null;

/// The signed-in account id, or null while signed out.
///
/// Selecting only the id means profile edits for the same account do not
/// invalidate state that belongs to that account.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select(_userIdOf));
});

/// Rebuilds the calling provider when the signed-in account changes.
///
/// Providers use this instead of watching [currentUserIdProvider]: a shared
/// intermediate provider can be recomputed lazily inside a widget build, and
/// its fan-out to every account-scoped provider would then schedule refreshes
/// mid-build. Selecting on [authProvider] directly is evaluated when the auth
/// state is set, outside any build.
String? watchCurrentUserId(Ref ref) =>
    ref.watch(authProvider.select(_userIdOf));
