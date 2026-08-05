import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/admin_router.dart';
import 'theme/admin_theme.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'Riksa Admin',
      debugShowCheckedModeBanner: kDebugMode,
      theme: AdminTheme.light,
      routerConfig: router,
    );
  }
}
