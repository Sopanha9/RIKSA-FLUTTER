import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';

import 'router/app_router.dart';
import '../core/providers/locale_provider.dart';
import '../core/theme/app_theme.dart';

class RiksaApp extends ConsumerWidget {
  const RiksaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Riksa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      routerConfig: router,
    );
  }
}
