import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_toggle.dart';

/// Page frame for the sign-in screens: the lavender ground, an optional back
/// button and language toggle along the top, and content that rides in the
/// upper part of the screen when it fits and scrolls when the keyboard needs
/// the room.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.showLanguageToggle = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool showLanguageToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final hasTopBar = onBack != null || showLanguageToggle;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            const contentPadding = EdgeInsets.fromLTRB(24, 12, 24, 20);
            final minimumContentHeight =
                viewport.maxHeight > contentPadding.vertical
                ? viewport.maxHeight - contentPadding.vertical
                : 0.0;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: contentPadding,
                  sliver: SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minimumContentHeight,
                      ),
                      child: Align(
                        alignment: const Alignment(0, -.6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (hasTopBar)
                                _AuthTopBar(
                                  onBack: onBack,
                                  showLanguageToggle: showLanguageToggle,
                                ),
                              child,
                            ],
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
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.onBack, required this.showLanguageToggle});

  final VoidCallback? onBack;
  final bool showLanguageToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: context.riksa.surface,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        const Spacer(),
        if (showLanguageToggle) const LanguageToggle(),
      ],
    ),
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
    final palette = context.riksa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow?.trim().isNotEmpty == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: palette.brandSoft,
              borderRadius: AppRadii.fullBorder,
            ),
            child: Text(
              eyebrow!,
              style: RiksaTypography.bodyStyleFor(
                eyebrow!,
                textTheme.labelSmall?.copyWith(
                  color: palette.brand,
                  letterSpacing: .4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: RiksaTypography.titleStyleFor(
            title,
            textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: RiksaTypography.bodyStyleFor(
            subtitle,
            textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Groups a sign-in form. Fields inside read as placeholders with a leading
/// icon, on white with a hairline border, the way the reference draws them.
class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true,
          fillColor: palette.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.largeBorder,
            borderSide: BorderSide(color: palette.outline),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.largeBorder,
            borderSide: BorderSide(
              color: palette.outline.withValues(alpha: .7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.largeBorder,
            borderSide: BorderSide(color: palette.brand, width: 2),
          ),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkFaint,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: palette.inkMuted,
          ),
        ),
      ),
      child: child,
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Row(
      children: [
        Expanded(child: Divider(color: palette.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: RiksaTypography.bodyStyleFor(
              label,
              Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.inkMuted),
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.outline)),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: error.withValues(alpha: .08),
          borderRadius: AppRadii.mediumBorder,
          border: Border.all(color: error.withValues(alpha: .22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error,
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
