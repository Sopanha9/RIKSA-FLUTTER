import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';

String? publicProfilePath(String? userId) {
  final normalized = userId?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (const {'settings', 'edit', 'setup'}.contains(normalized.toLowerCase())) {
    return null;
  }
  return '/profile/${Uri.encodeComponent(normalized)}';
}

/// Opens the signed-in learner's own profile.
///
/// The profile is a tab root, so this switches to its branch instead of
/// pushing it: a push would stack the profile on top of whichever tab it was
/// opened from, where the shell reads a pushed screen and hides the tabs.
void openOwnProfile(BuildContext context) => context.go('/profile');

/// Opens the profile of whoever [userId] names, from a post author, a
/// leaderboard row or anywhere else a learner's name is tappable.
///
/// The learner's own id goes to their profile tab through [openOwnProfile].
/// Pushing `/profile/<own id>` would be redirected to `/profile` and land as a
/// pushed screen on the current tab, which hides the tabs and leaves the
/// profile with no way back out.
void openUserProfile(BuildContext context, String? userId) {
  final path = publicProfilePath(userId);
  if (path == null) return;
  if (_isSignedInUser(context, userId!.trim())) {
    openOwnProfile(context);
  } else {
    context.push(path);
  }
}

bool _isSignedInUser(BuildContext context, String userId) {
  try {
    final auth = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authProvider);
    return auth is Authenticated && auth.userId == userId;
  } on StateError {
    // Widgets pumped alone in tests have no provider scope to ask.
    return false;
  }
}
