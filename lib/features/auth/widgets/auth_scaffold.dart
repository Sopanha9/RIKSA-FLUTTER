import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                const contentPadding = EdgeInsets.all(RiksaSpacing.md);
                final minimumContentHeight =
                    viewport.maxHeight > contentPadding.vertical
                    ? viewport.maxHeight - contentPadding.vertical
                    : 0.0;
                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: contentPadding,
                      sliver: SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minimumContentHeight,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: SizedBox(
                                width: double.infinity,
                                child: _AuthContent(
                                  onBack: onBack,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (onBack != null) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        const SizedBox(height: RiksaSpacing.md),
      ],
      child,
    ],
  );
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow?.trim().isNotEmpty == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF4A253D)
                  : AppColors.editorialPinkSoft,
              borderRadius: AppRadii.smallBorder,
            ),
            child: Text(
              eyebrow!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: dark
                    ? AppColors.editorialPink
                    : AppColors.editorialAubergine,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            color: dark ? context.riksa.ink : AppColors.editorialInk,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: dark ? context.riksa.inkMuted : AppColors.editorialMuted,
          ),
        ),
      ],
    );
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final dark = theme.brightness == Brightness.dark;
    final panelColor = dark
        ? theme.colorScheme.surfaceContainer
        : AppColors.editorialNeutralSurface;
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? 18 : 24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: AppRadii.extraLargeBorder,
        border: Border.all(
          color: dark ? palette.outline : AppColors.editorialOutline,
        ),
        boxShadow: RiksaElevation.low(theme.brightness),
      ),
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            surface: panelColor,
            surfaceContainer: dark
                ? theme.colorScheme.surfaceContainer
                : AppColors.editorialField,
            onSurface: dark ? palette.ink : AppColors.editorialInk,
            onSurfaceVariant: dark
                ? palette.inkMuted
                : AppColors.editorialMuted,
            outline: dark ? palette.outline : AppColors.editorialOutline,
          ),
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            fillColor: dark ? palette.canvas : AppColors.editorialField,
            prefixIconColor: dark ? palette.inkMuted : AppColors.editorialMuted,
            suffixIconColor: dark ? palette.inkMuted : AppColors.editorialMuted,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: dark ? palette.inkMuted : AppColors.editorialMuted,
            ),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: dark ? palette.inkMuted : AppColors.editorialMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.mediumBorder,
              borderSide: BorderSide(
                color: dark ? palette.outline : AppColors.editorialOutline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.mediumBorder,
              borderSide: BorderSide(
                color: dark ? palette.outline : AppColors.editorialOutline,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.mediumBorder,
              borderSide: BorderSide(color: AppColors.editorialPink, width: 2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.mediumBorder,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              backgroundColor: dark
                  ? const Color(0xFF4A253D)
                  : AppColors.editorialPinkSoft,
              foregroundColor: dark
                  ? AppColors.editorialPink
                  : AppColors.editorialAubergine,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: dark
                  ? AppColors.editorialPink
                  : AppColors.editorialAubergine,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              backgroundColor: panelColor,
              foregroundColor: dark
                  ? AppColors.editorialPink
                  : AppColors.editorialAubergine,
              side: BorderSide(
                color: dark ? palette.outline : AppColors.editorialOutline,
              ),
              minimumSize: const Size(0, 50),
              shape: const StadiumBorder(),
            ),
          ),
          textSelectionTheme: theme.textSelectionTheme.copyWith(
            cursorColor: AppColors.editorialPink,
            selectionColor: AppColors.editorialPink.withValues(alpha: .24),
            selectionHandleColor: AppColors.editorialPink,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = dark
        ? context.riksa.outline
        : AppColors.editorialOutline;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: dark ? context.riksa.inkMuted : AppColors.editorialMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: .08),
          borderRadius: AppRadii.mediumBorder,
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: .22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? context.riksa.canvas
          : AppColors.editorialNeutralCanvas,
    );
  }
}
