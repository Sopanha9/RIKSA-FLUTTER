import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../l10n/gen/app_localizations.dart';

abstract final class AuthTextStyles {
  static const heading = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: -.4,
    color: Color(0xFF20212C),
  );
  static const field = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );
  static const supporting = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.muted,
  );
  static const button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.footer,
    this.expandedHeaderMinHeight = 740,
  });

  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final double expandedHeaderMinHeight;

  @override
  Widget build(BuildContext context) {
    // The reference uses a light auth surface, including in system dark mode.
    final theme = AppTheme.light;
    const accent = Color(0xFF4548FF);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE9E9F0)),
    );
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme
            .apply(fontFamily: 'Poppins')
            .copyWith(
              bodyLarge: AuthTextStyles.field.copyWith(
                color: const Color(0xFF20212C),
              ),
              bodyMedium: AuthTextStyles.supporting,
              labelLarge: AuthTextStyles.button,
            ),
        iconTheme: const IconThemeData(size: 20, color: Color(0xFF858591)),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            iconSize: 20,
            minimumSize: const Size(48, 48),
          ),
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: accent,
          onPrimary: Colors.white,
          error: const Color(0xFFB3261E),
          onError: Colors.white,
          surface: const Color(0xFFFCFCFE),
          outline: const Color(0xFFE9E9F0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          // Material scales floating labels by .75: 16 gives a visible 12px label.
          labelStyle: AuthTextStyles.field.copyWith(
            color: const Color(0xFF292A35),
          ),
          hintStyle: AuthTextStyles.field.copyWith(
            color: const Color(0xFF858591),
          ),
          errorStyle: const TextStyle(fontSize: 12, height: 1.3),
          suffixIconColor: const Color(0xFF858591),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: accent),
          ),
          errorBorder: border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFB3261E)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            iconSize: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: AuthTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF535360),
            backgroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            iconSize: 20,
            side: const BorderSide(color: Color(0xFFE9E9F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: AuthTextStyles.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: AuthTextStyles.button,
            minimumSize: const Size(0, 44),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE9E9F0),
          thickness: 1,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AuthBackground(),
            SafeArea(
              maintainBottomViewPadding: true,
              child: _KeyboardStableViewport(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxHeight < expandedHeaderMinHeight;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(24, compact ? 4 : 12, 24, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthTopBar(onBack: onBack, showBrand: compact),
                            SizedBox(height: compact ? 4 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!compact) ...[
                                    const _AuthBrand(),
                                    const SizedBox(height: 20),
                                  ],
                                  child,
                                ],
                              ),
                            ),
                            ?footer,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile browsers may resize the Flutter view instead of reporting keyboard
/// insets. Keep the pre-keyboard canvas while focus is inside the form, so the
/// keyboard overlays the page just as it does with resizeToAvoidBottomInset off.
class _KeyboardStableViewport extends StatefulWidget {
  const _KeyboardStableViewport({required this.builder});

  final LayoutWidgetBuilder builder;

  @override
  State<_KeyboardStableViewport> createState() =>
      _KeyboardStableViewportState();
}

class _KeyboardStableViewportState extends State<_KeyboardStableViewport> {
  Size? _restingSize;
  bool _hasFocus = false;
  bool _keyboardResize = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) => _hasFocus = focused,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final resting = _restingSize;
          if (resting == null || size.width != resting.width) {
            // Width changes indicate a new window size or orientation.
            _restingSize = size;
            _keyboardResize = false;
          } else if (size.height >= resting.height) {
            _restingSize = size;
            _keyboardResize = false;
          } else if (_hasFocus || _keyboardResize) {
            // Preserve this until the browser restores the viewport, including
            // the frame between losing focus and the keyboard closing.
            _keyboardResize = true;
          } else {
            _restingSize = size;
          }

          final height = _restingSize!.height;
          return OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: height,
            maxHeight: height,
            child: SizedBox(
              width: size.width,
              height: height,
              child: LayoutBuilder(builder: widget.builder),
            ),
          );
        },
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: AuthTextStyles.heading),
        const SizedBox(height: 10),
        Text(subtitle, style: AuthTextStyles.supporting),
      ],
    );
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AuthAccountPrompt extends StatelessWidget {
  const AuthAccountPrompt({
    super.key,
    required this.prompt,
    required this.label,
    required this.onTap,
  });

  final String prompt;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(prompt, style: AuthTextStyles.supporting),
          Semantics(
            link: true,
            enabled: onTap != null,
            label: label,
            onTap: onTap,
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              excludeFromSemantics: true,
              child: Text(
                label,
                style: AuthTextStyles.supporting.copyWith(
                  color: onTap == null
                      ? AppTheme.muted
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AuthTextStyles.supporting.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Requirement(
          label: strings.passwordEightCharacters,
          met: password.length >= 8,
        ),
        _Requirement(
          label: strings.passwordUppercase,
          met: RegExp('[A-Z]').hasMatch(password),
        ),
        _Requirement(
          label: strings.passwordLowercase,
          met: RegExp('[a-z]').hasMatch(password),
        ),
        _Requirement(
          label: strings.passwordNumber,
          met: RegExp(r'\d').hasMatch(password),
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppTheme.primary : AppTheme.muted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: met ? .1 : .06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_rounded : Icons.circle_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({this.onBack, this.showBrand = false});

  final VoidCallback? onBack;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton.filledTonal(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF777783),
            ),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        if (showBrand) const _AuthBrand(inline: true),
        const Spacer(),
        const LanguageToggle(),
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(
        color: Color(0xFFFCFCFE),
        child: RepaintBoundary(
          child: ClipRect(child: CustomPaint(painter: _AuthSmokePainter())),
        ),
      ),
    );
  }
}

class _AuthSmokePainter extends CustomPainter {
  const _AuthSmokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Blurred, solid-color shapes create a soft haze without a gradient.
    // Keep its depth fixed so it stays at the top on tall screens.
    final radius = (size.width * .62).clamp(200.0, 440.0);
    final haze = Paint()
      ..color = const Color(0x99FFDA9C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 18),
        width: radius * 2,
        height: 230,
      ),
      haze,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 - radius * .35, 62),
        width: radius,
        height: 160,
      ),
      Paint()
        ..color = const Color(0x33FFE8BD)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
  }

  @override
  bool shouldRepaint(_AuthSmokePainter oldDelegate) => false;
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({this.inline = false});

  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: inline ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: inline ? 32 : 48,
          height: inline ? 32 : 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF4548FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            'R',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: inline ? 22 : 30,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: inline ? 0 : 6, width: inline ? 8 : 0),
        const Text(
          'Riksa',
          style: TextStyle(
            color: Color(0xFF242433),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -.4,
          ),
        ),
      ],
    );
  }
}
