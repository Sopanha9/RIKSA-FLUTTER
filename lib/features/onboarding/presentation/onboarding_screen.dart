import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The first-run product introduction. Final illustration assets can replace
/// [OnboardingIllustration] without affecting the paging or navigation code.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _pageIndex = 0;

  static const _pages = <OnboardingPageData>[
    OnboardingPageData(
      illustration: OnboardingIllustrationType.learn,
      title: 'Learn what actually\ninterests you.',
      description:
          'Discover lessons, ideas, and content built around what you actually want to learn.',
      ctaLabel: 'Continue',
    ),
    OnboardingPageData(
      illustration: OnboardingIllustrationType.achieve,
      title: 'Learn. Compete.\nLevel up.',
      description:
          'Take on challenges, earn achievements, build your streak, and watch your progress grow.',
      ctaLabel: 'Continue',
    ),
    OnboardingPageData(
      illustration: OnboardingIllustrationType.connect,
      title: 'Your people.\nYour progress.',
      description:
          'Share what you learn, meet curious people, and grow together with a community that keeps you moving.',
      ctaLabel: 'Get Started  \u2192',
    ),
  ];

  void _next() {
    if (_pageIndex == _pages.length - 1) {
      context.go('/language-select');
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OnboardingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _pageIndex < _pages.length - 1 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: TextButton(
                    onPressed: _pageIndex < _pages.length - 1
                        ? () => context.go('/language-select')
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _OnboardingColors.secondaryText,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _pageIndex = value),
                itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
              ),
            ),
            _PageIndicator(activeIndex: _pageIndex, count: _pages.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _OnboardingColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_pages[_pageIndex].ctaLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.illustration,
    required this.title,
    required this.description,
    required this.ctaLabel,
  });

  final OnboardingIllustrationType illustration;
  final String title;
  final String description;
  final String ctaLabel;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .92, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: ((value - .92) / .08).clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - value) / .08),
                  child: Transform.scale(scale: value, child: child),
                ),
              ),
              child: OnboardingIllustration(type: data.illustration),
            ),
          ),
          const Spacer(flex: 1),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
            ),
            child: Text(
              data.title,
              style: const TextStyle(
                color: _OnboardingColors.mainText,
                fontSize: 30,
                height: 1.12,
                letterSpacing: -.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            style: const TextStyle(
              color: _OnboardingColors.secondaryText,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? _OnboardingColors.primary : _OnboardingColors.strongBorder,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

enum OnboardingIllustrationType { learn, achieve, connect }

/// TODO(design): Replace these lightweight hand-drawn placeholders with the
/// final illustration assets when they are available.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.type});

  final OnboardingIllustrationType type;

  @override
  Widget build(BuildContext context) {
    final config = switch (type) {
      OnboardingIllustrationType.learn => _IllustrationConfig(Icons.menu_book_rounded, 'LEARN', const Color(0xFFDFF7E7)),
      OnboardingIllustrationType.achieve => _IllustrationConfig(Icons.emoji_events_outlined, '+120 XP', const Color(0xFFFFF6C8)),
      OnboardingIllustrationType.connect => _IllustrationConfig(Icons.groups_2_outlined, 'TOGETHER', const Color(0xFFE2F3FE)),
    };
    return SizedBox(
      width: 285,
      height: 275,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -.06,
            child: Container(
              width: 222,
              height: 222,
              decoration: BoxDecoration(color: config.background, borderRadius: BorderRadius.circular(44)),
            ),
          ),
          Icon(config.icon, size: 128, color: _OnboardingColors.mainText),
          Positioned(
            top: 35,
            right: 9,
            child: _DoodleChip(label: config.label, icon: type == OnboardingIllustrationType.achieve ? Icons.star_rounded : Icons.auto_awesome_rounded),
          ),
          if (type == OnboardingIllustrationType.connect) ...[
            const Positioned(left: 13, top: 76, child: _DoodleIcon(icon: Icons.favorite_border_rounded, color: Color(0xFFF91880))),
            const Positioned(right: 21, bottom: 50, child: _DoodleIcon(icon: Icons.chat_bubble_outline_rounded, color: Color(0xFF1D9BF0))),
          ] else if (type == OnboardingIllustrationType.learn) ...[
            const Positioned(left: 15, bottom: 52, child: _DoodleIcon(icon: Icons.lightbulb_outline_rounded, color: Color(0xFFFFB800))),
            const Positioned(right: 18, bottom: 42, child: _DoodleIcon(icon: Icons.edit_outlined, color: Color(0xFF22C55E))),
          ] else
            const Positioned(left: 12, bottom: 56, child: _DoodleIcon(icon: Icons.local_fire_department_outlined, color: Color(0xFFF97316))),
        ],
      ),
    );
  }
}

class _IllustrationConfig {
  const _IllustrationConfig(this.icon, this.label, this.background);
  final IconData icon;
  final String label;
  final Color background;
}

class _DoodleChip extends StatelessWidget {
  const _DoodleChip({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: .08,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _OnboardingColors.strongBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: _OnboardingColors.primary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
        ),
      );
}

class _DoodleIcon extends StatelessWidget {
  const _DoodleIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _OnboardingColors.strongBorder)),
        child: Icon(icon, size: 21, color: color),
      );
}

abstract final class _OnboardingColors {
  static const primary = Color(0xFF22C55E);
  static const mainText = Color(0xFF0F1419);
  static const secondaryText = Color(0xFF536471);
  static const background = Color(0xFFFFFFFF);
  static const strongBorder = Color(0xFFCFD9DE);
}
