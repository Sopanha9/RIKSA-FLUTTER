import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A one-time code shown as a row of boxes, one per character.
///
/// A single invisible [TextField] sits on top of the boxes and does the real
/// work, so the keyboard, paste, and SMS/email autofill behave like any text
/// field; the boxes only draw what it holds.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.length,
    this.fieldKey,
    this.alphanumeric = false,
    this.groupSize = 0,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final int length;

  /// Key for the underlying text field, for tests and autofill.
  final Key? fieldKey;

  /// Letters and digits (upper-cased) instead of digits only.
  final bool alphanumeric;

  /// Draws a dash after every [groupSize] boxes; 0 for none.
  final int groupSize;
  final bool enabled;

  /// Turns the boxes red and shakes them once.
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Called once the last box is filled.
  final ValueChanged<String>? onCompleted;
  final String? semanticLabel;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(OtpCodeField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (widget.hasError &&
        !old.hasError &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final group = widget.groupSize;
    final dashes = group > 0 ? (widget.length - 1) ~/ group : 0;

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          const dashWidth = 14.0;
          final available =
              constraints.maxWidth -
              gap * (widget.length - 1 + dashes) -
              dashWidth * dashes;
          final box = math.min(56.0, available / widget.length);
          final height = (box * 1.22).clamp(48.0, 66.0);

          final boxes = <Widget>[];
          for (var i = 0; i < widget.length; i++) {
            if (i > 0) boxes.add(const SizedBox(width: gap));
            if (group > 0 && i > 0 && i % group == 0) {
              boxes
                ..add(_Dash(width: dashWidth))
                ..add(const SizedBox(width: gap));
            }
            boxes.add(
              _CodeBox(
                width: box,
                height: height,
                char: i < text.length ? text[i] : null,
                active:
                    _focus.hasFocus &&
                    widget.enabled &&
                    (i == text.length ||
                        (text.length == widget.length &&
                            i == widget.length - 1)),
                error: widget.hasError,
                enabled: widget.enabled,
              ),
            );
          }

          return AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 5) * 10 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: boxes,
                  ),
                  Positioned.fill(
                    child: TextField(
                      key: widget.fieldKey,
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      showCursor: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: widget.alphanumeric
                          ? TextInputType.visiblePassword
                          : TextInputType.number,
                      textCapitalization: widget.alphanumeric
                          ? TextCapitalization.characters
                          : TextCapitalization.none,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          widget.alphanumeric
                              ? RegExp('[A-Za-z0-9]')
                              : RegExp('[0-9]'),
                        ),
                        const _UpperCase(),
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      // Invisible: the boxes above draw the text.
                      style: const TextStyle(
                        color: Colors.transparent,
                        height: 1,
                      ),
                      cursorColor: Colors.transparent,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        widget.onChanged?.call(value);
                        if (value.length == widget.length) {
                          widget.onCompleted?.call(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.width,
    required this.height,
    required this.char,
    required this.active,
    required this.error,
    required this.enabled,
  });

  final double width;
  final double height;
  final String? char;
  final bool active;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final filled = char != null;
    final accent = error ? theme.colorScheme.error : palette.brand;
    final borderColor = error
        ? theme.colorScheme.error
        : active
        ? palette.brand
        : filled
        ? palette.brand.withValues(alpha: .45)
        : palette.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: .10)
            : palette.surface.withValues(alpha: enabled ? 1 : .5),
        borderRadius: BorderRadius.circular(math.min(16, width * .3)),
        border: Border.all(color: borderColor, width: active ? 2 : 1.4),
        boxShadow: [
          if (active)
            BoxShadow(
              color: accent.withValues(alpha: .28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: filled
          ? TweenAnimationBuilder<double>(
              key: ValueKey(char),
              tween: Tween(
                begin: MediaQuery.disableAnimationsOf(context) ? 1 : .4,
                end: 1,
              ),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                char!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: error ? theme.colorScheme.error : palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          : active
          ? const _Caret()
          : null,
    );
  }
}

/// A blinking bar in the box that takes the next character.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _blink.value = 1;
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _blink,
    builder: (context, _) => Opacity(
      opacity: _blink.value < .5 ? 1 : 0,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: context.riksa.brand,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ),
  );
}

class _Dash extends StatelessWidget {
  const _Dash({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 3,
    decoration: BoxDecoration(
      color: context.riksa.outline,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _UpperCase extends TextInputFormatter {
  const _UpperCase();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
