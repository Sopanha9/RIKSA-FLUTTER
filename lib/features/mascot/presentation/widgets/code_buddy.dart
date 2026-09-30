import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/mascot.dart';
import '../../providers/mascot_provider.dart';
import 'mascot_speech.dart';
import 'mascot_view.dart';

/// The learner's buddy keeping them company while they type a one-time code:
/// it waves hello, thinks along as boxes fill, cheers when the code is
/// complete and looks sad when the code was wrong.
class CodeBuddy extends ConsumerStatefulWidget {
  const CodeBuddy({
    super.key,
    required this.controller,
    required this.length,
    this.hasError = false,
    this.startLine,
    this.size = 92,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;

  /// What the buddy says before anything is typed.
  final String? startLine;
  final double size;

  @override
  ConsumerState<CodeBuddy> createState() => _CodeBuddyState();
}

class _CodeBuddyState extends ConsumerState<CodeBuddy> {
  final _mascot = MascotController(MascotMood.idle);
  int _typed = 0;

  @override
  void initState() {
    super.initState();
    _typed = widget.controller.text.length;
    widget.controller.addListener(_onText);
    _mascot.react(MascotMood.greeting);
  }

  @override
  void didUpdateWidget(CodeBuddy old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (widget.hasError && !old.hasError) {
      _mascot.mood = MascotMood.sad;
    } else if (!widget.hasError && old.hasError) {
      _mascot.mood = _restingMood(_typed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _mascot.dispose();
    super.dispose();
  }

  MascotMood _restingMood(int typed) {
    if (typed == 0) return MascotMood.idle;
    if (typed >= widget.length) return MascotMood.happy;
    return MascotMood.thinking;
  }

  void _onText() {
    final typed = widget.controller.text.length;
    if (typed == _typed) return;
    final before = _typed;
    setState(() => _typed = typed);
    if (widget.hasError) return;
    _mascot.mood = _restingMood(typed);
    if (typed >= widget.length && before < widget.length) {
      _mascot.react(MascotMood.celebrate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final name = profile?.name ?? MascotProfile.defaultName(species);
    final left = widget.length - _typed;
    final line = widget.hasError
        ? l10n.codeBuddyWrong
        : _typed == 0
        ? (widget.startLine ?? l10n.codeBuddyStart)
        : left > 0
        ? l10n.codeBuddyLeft(left)
        : l10n.codeBuddyDone;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MascotView(
          species: species,
          size: widget.size,
          controller: _mascot,
          interactive: true,
          semanticLabel: name,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: MascotSpeechBubble(
            key: const ValueKey('code-buddy-line'),
            line: line,
            tail: SpeechTail.left,
            maxWidth: 240,
            textAlign: TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
