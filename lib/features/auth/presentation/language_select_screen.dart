import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_brand.dart';

/// Language selection: two radio cards and one Continue.
///
/// Both languages name themselves in their own script, so the screen is
/// readable before the learner has chosen either.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  late String _selected = ref.read(localeProvider).hasSelection
      ? ref.read(localeProvider).locale.languageCode
      : 'km';
  bool _submitting = false;

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
      router.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: canPop
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              onPressed: () => context.pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Language',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred language for the app.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _LanguageCard(
                    key: const Key('language_en'),
                    flagAsset:
                        'assets/images/logos/Flag_of_the_United_Kingdom.svg.png',
                    languageName: 'English',
                    caption: 'Learn in English',
                    isSelected: _selected == 'en',
                    onTap: () => setState(() => _selected = 'en'),
                  ),
                  const SizedBox(height: 14),
                  _LanguageCard(
                    key: const Key('language_km'),
                    flagAsset: 'assets/images/logos/Flag_of_Cambodia.svg',
                    languageName: 'ខ្មែរ',
                    caption: 'រៀនជាភាសាខ្មែរ',
                    isSelected: _selected == 'km',
                    onTap: () => setState(() => _selected = 'km'),
                  ),
                  const Expanded(child: _LanguageDoodles()),
                  FilledButton(
                    key: const Key('language_continue'),
                    onPressed: _submitting ? null : _confirmSelection,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_selected == 'km' ? 'បន្ត' : 'Continue'),
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

class _LanguageDoodles extends StatelessWidget {
  const _LanguageDoodles();

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 12,
            bottom: 36,
            child: RiksaDoodle(
              RiksaDoodleKind.globe,
              size: 64,
              color: palette.brand.withValues(alpha: .45),
            ),
          ),
          Positioned(
            left: 70,
            bottom: 24,
            child: RiksaDoodle(
              RiksaDoodleKind.squiggle,
              size: 26,
              color: AppColors.lime,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 70,
            child: RiksaDoodle(
              RiksaDoodleKind.sparkle,
              size: 40,
              color: palette.brand.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    super.key,
    required this.flagAsset,
    required this.languageName,
    required this.caption,
    required this.isSelected,
    required this.onTap,
  });

  final String flagAsset;
  final String languageName;
  final String caption;
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
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Row(
              children: [
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
                const SizedBox(width: 14),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageName,
                        style: RiksaTypography.bodyStyleFor(
                          languageName,
                          theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: RiksaTypography.bodyStyleFor(
                          caption,
                          theme.textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
