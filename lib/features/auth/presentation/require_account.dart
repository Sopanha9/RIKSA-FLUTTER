import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Sends a guest to sign in before an action that needs an account, then
/// returns them to the current in-app location.
bool requireAccount(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) {
  if (ref.read(authProvider) is Authenticated) return true;

  final here = GoRouterState.of(context).uri.toString();
  final login = Uri(
    path: '/auth/login',
    queryParameters: {'from': here, 'reason': reason},
  );
  context.push(login.toString());
  return false;
}
