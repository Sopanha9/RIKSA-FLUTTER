import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';

/// First-run language selection shown before the illustrated onboarding pages.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  String _selected = 'km';
  bool _submitting = false;

  Future<void> _confirmSelection() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected));
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: constraints.maxHeight < 700 ? 54 : 96),
                    Text(
                      'Select your preferred\nlanguage',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This helps us show content and features in your language.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LanguageCard(
                      flagAsset: 'assets/images/logos/Flag_of_Cambodia.svg',
                      languageName: 'Khmer',
                      languageNameNative: 'ភាសាខ្មែរ',
                      isSelected: _selected == 'km',
                      onTap: () => setState(() => _selected = 'km'),
                    ),
                    const SizedBox(height: 14),
                    _LanguageCard(
                      flagAsset:
                          'assets/images/logos/Flag_of_the_United_Kingdom.svg.png',
                      languageName: 'English',
                      languageNameNative: 'English',
                      isSelected: _selected == 'en',
                      onTap: () => setState(() => _selected = 'en'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You can change the language later in your settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        key: const Key('language_continue'),
                        onPressed: _submitting ? null : _confirmSelection,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lightTextPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.lightTextPrimary,
                          disabledForegroundColor: Colors.white70,
                          shape: const StadiumBorder(),
                        ),
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.flagAsset,
    required this.languageName,
    required this.languageNameNative,
    required this.isSelected,
    required this.onTap,
  });

  final String flagAsset;
  final String languageName;
  final String languageNameNative;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: languageName,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 42,
                  height: 28,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageNameNative,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
