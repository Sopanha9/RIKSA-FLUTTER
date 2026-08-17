import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

/// A language toggle pill that switches between English and Khmer.
class LanguageToggle extends ConsumerStatefulWidget {
  const LanguageToggle({super.key});

  static const double _segmentWidth = 56;

  @override
  ConsumerState<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends ConsumerState<LanguageToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    final isEnglish = ref.read(localeProvider).languageCode == 'en';
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: isEnglish ? 0 : 1,
    );
    _slide = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setLocale(Locale locale) {
    ref.read(localeProvider.notifier).setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);

    ref.listen(localeProvider, (_, next) {
      if (next.languageCode == 'en') {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              return Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  _slide.value,
                )!,
                child: Container(
                  width: LanguageToggle._segmentWidth,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                label: 'EN',
                selectedAtStart: true,
                animation: _slide,
                onTap: () => _setLocale(const Locale('en')),
              ),
              _Segment(
                label: 'ខ្មែរ',
                selectedAtStart: false,
                animation: _slide,
                onTap: () => _setLocale(const Locale('km')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selectedAtStart,
    required this.animation,
    required this.onTap,
  });

  final String label;

  /// Whether this segment is selected when the animation is at its start.
  final bool selectedAtStart;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: LanguageToggle._segmentWidth,
        height: 32,
        child: Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = selectedAtStart
                  ? 1 - animation.value
                  : animation.value;
              return Text(
                label,
                style: TextStyle(
                  color: Color.lerp(
                    theme.colorScheme.onSurface,
                    theme.colorScheme.onPrimary,
                    t,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.lerp(FontWeight.w500, FontWeight.w600, t),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
