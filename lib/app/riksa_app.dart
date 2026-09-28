import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';

import 'realtime_sync.dart';
import 'router/app_router.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/theme/app_theme.dart';

class RiksaApp extends ConsumerWidget {
  const RiksaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).locale;
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);
    // Keeps the live connection and its feed and quest updates running for
    // the whole session.
    ref.watch(realtimeSyncProvider);

    return MaterialApp.router(
      title: 'Riksa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      routerConfig: router,
      builder: (context, child) => _LocaleTransition(
        locale: locale,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _LocaleTransition extends StatefulWidget {
  const _LocaleTransition({required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  State<_LocaleTransition> createState() => _LocaleTransitionState();
}

class _LocaleTransitionState extends State<_LocaleTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      value: 1,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: .78, end: 1).animate(curve);
    _position = Tween<Offset>(
      begin: const Offset(0, .008),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didUpdateWidget(covariant _LocaleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale.languageCode == widget.locale.languageCode) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}
