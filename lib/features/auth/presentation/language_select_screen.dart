import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_speech.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/mascot_provider.dart';

/// Language selection, framed as the language the learner's buddy speaks.
///
/// Each option previews what the buddy would say in it, and the whole page
/// switches to the highlighted language as it is tapped, so it can be read
/// before it is chosen. Nothing is saved until Continue.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  final _buddy = MascotController();
  late String _selected = ref.read(localeProvider).hasSelection
      ? ref.read(localeProvider).locale.languageCode
      : 'km';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buddy.react(MascotMood.greeting);
    });
  }

  void _pick(String code) {
    if (code != _selected) setState(() => _selected = code);
    _buddy.react(MascotMood.greeting);
  }

  Future<void> _confirmSelection() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected));
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/onboarding/setup');
    }
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final name = profile?.name ?? MascotProfile.defaultName(species);
    // Preview the page in the highlighted language.
    return Localizations.override(
      context: context,
      locale: Locale(_selected),
      child: Builder(
        builder: (context) => _page(context, species: species, name: name),
      ),
    );
  }

  Widget _page(
    BuildContext context, {
    required MascotSpecies species,
    required String name,
  }) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final isDark = theme.brightness == Brightness.dark;
    final title = strings.languageSelectTitle(name);
    final subtitle = strings.languageSelectSubtitle(name);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          Positioned.fill(child: MascotSceneBackdrop(species: species)),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: _SpeakingBuddy(
                            species: species,
                            controller: _buddy,
                            line: strings.languageMascotGreeting(name),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 12,
                        child: RiksaBackButton(
                          key: const ValueKey('language-select-back'),
                          fallbackLocation: '/mascot-select',
                          style: IconButton.styleFrom(
                            backgroundColor: palette.surface.withValues(
                              alpha: .92,
                            ),
                            foregroundColor: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MascotSceneSheet(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      key: const Key('language_title'),
                      style: RiksaTypography.titleStyleFor(
                        title,
                        theme.textTheme.headlineMedium,
                        khmerHeight: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: RiksaTypography.bodyStyleFor(
                        subtitle,
                        theme.textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final (code, flag, label) in const [
                      (
                        'km',
                        'assets/images/logos/Flag_of_Cambodia.svg',
                        'ខ្មែរ',
                      ),
                      (
                        'en',
                        'assets/images/logos/Flag_of_the_United_Kingdom.svg.png',
                        'English',
                      ),
                    ]) ...[
                      _LanguageCard(
                        key: Key('language_$code'),
                        flagAsset: flag,
                        languageName: label,
                        // Each card quotes the buddy in its own language,
                        // whatever language the page is previewing.
                        quote: lookupAppLocalizations(
                          Locale(code),
                        ).languageMascotGreeting(name),
                        isSelected: _selected == code,
                        onTap: () => _pick(code),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    FilledButton(
                      key: const Key('language_continue'),
                      onPressed: _submitting ? null : _confirmSelection,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? palette.brand
                            : palette.brandStrong,
                        foregroundColor: palette.onBrand,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              strings.continueLabel,
                              style: RiksaTypography.bodyStyleFor(
                                strings.continueLabel,
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The buddy with a speech bubble that types out [line] whenever it
/// changes.
class _SpeakingBuddy extends StatelessWidget {
  const _SpeakingBuddy({
    required this.species,
    required this.controller,
    required this.line,
  });

  final MascotSpecies species;
  final MascotController controller;
  final String line;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxHeight >= 200;
        final bubbleRoom = roomy ? 84.0 : 0.0;
        final size = ((box.maxHeight - bubbleRoom) / MascotView.heightFactor)
            .clamp(0.0, 190.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // The buddy's box keeps headroom for hops; tuck the bubble into
            // it so the tail points at the head, not at empty space.
            if (roomy)
              Transform.translate(
                offset: Offset(0, size * .2),
                child: MascotSpeechBubble(line: line),
              ),
            MascotView(
              species: species,
              size: size,
              controller: controller,
              interactive: true,
            ),
          ],
        );
      },
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    super.key,
    required this.flagAsset,
    required this.languageName,
    required this.quote,
    required this.isSelected,
    required this.onTap,
  });

  final String flagAsset;
  final String languageName;
  final String quote;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    return Semantics(
      button: true,
      selected: isSelected,
      label: languageName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.largeBorder,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadii.largeBorder,
              border: Border.all(
                color: isSelected ? palette.brand : palette.outline,
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: .12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      width: 38,
                      height: 26,
                      child: flagAsset.endsWith('.svg')
                          ? SvgPicture.asset(flagAsset, fit: BoxFit.cover)
                          : Image.asset(flagAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageName,
                          style: RiksaTypography.bodyStyleFor(
                            languageName,
                            theme.textTheme.titleSmallBold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '“$quote”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.bodyStyleFor(
                            quote,
                            theme.textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                              // Khmer has no italic; a synthetic slant reads
                              // as broken.
                              fontStyle: RiksaTypography.containsKhmer(quote)
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: duration,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? palette.brand : palette.inkFaint,
                        width: isSelected ? 6.5 : 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
