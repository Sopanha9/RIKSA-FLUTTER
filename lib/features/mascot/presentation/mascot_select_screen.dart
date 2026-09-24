import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/mascot.dart';
import '../providers/mascot_provider.dart';
import 'widgets/mascot_scene.dart';
import 'widgets/mascot_view.dart';

/// First-run step between the welcome and language selection: the learner
/// picks the buddy that will study with them, and names it.
class MascotSelectScreen extends ConsumerStatefulWidget {
  const MascotSelectScreen({super.key});

  @override
  ConsumerState<MascotSelectScreen> createState() => _MascotSelectScreenState();
}

class _MascotSelectScreenState extends ConsumerState<MascotSelectScreen> {
  final _stage = MascotController();
  final _name = TextEditingController();
  late MascotSpecies _species;

  /// Whether the learner typed a name. Until then the field follows the
  /// selected species' default name.
  bool _nameEdited = false;
  bool _selectionEdited = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(mascotProvider).profile;
    _species = saved?.species ?? MascotSpecies.crocodile;
    _name.text = saved?.name ?? MascotProfile.defaultName(_species);
    _nameEdited = saved != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MascotScenes.precacheAll(context);
      _stage.react(MascotMood.greeting);
    });
  }

  void _select(MascotSpecies species) {
    if (species == _species) {
      _stage.react(MascotMood.happy);
      return;
    }
    setState(() {
      _selectionEdited = true;
      _species = species;
      if (!_nameEdited) _name.text = MascotProfile.defaultName(species);
    });
    _stage.react(MascotMood.greeting);
  }

  Future<void> _continue() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    await ref.read(mascotProvider.notifier).choose(_species, _name.text);
    if (!mounted) return;
    _stage.react(MascotMood.celebrate);
    // Opened from settings it returns there; on first run, which replaces the
    // stack, it carries on to setup.
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/onboarding/setup');
    }
  }

  @override
  void dispose() {
    _stage.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MascotState>(mascotProvider, (previous, next) {
      final saved = next.profile;
      if (saved == null || _selectionEdited || _nameEdited || _submitting) {
        return;
      }
      setState(() {
        _species = saved.species;
        _name.text = saved.name;
        _nameEdited = true;
      });
    });
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.canvas,
        body: Stack(
          children: [
            Positioned.fill(child: MascotSceneBackdrop(species: _species)),
            Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: _Stage(
                      species: _species,
                      controller: _stage,
                      name: _name,
                      traits: _traits(strings, _species),
                      tapHint: strings.mascotTapHint,
                    ),
                  ),
                ),
                MascotSceneSheet(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.mascotSelectTitle,
                        style: RiksaTypography.titleStyleFor(
                          strings.mascotSelectTitle,
                          theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.mascotSelectSubtitle,
                        style: RiksaTypography.bodyStyleFor(
                          strings.mascotSelectSubtitle,
                          theme.textTheme.bodyMedium?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final species in MascotSpecies.values) ...[
                            if (species != MascotSpecies.values.first)
                              const SizedBox(width: 12),
                            Expanded(
                              child: _SpeciesTile(
                                key: Key('mascot_${species.name}'),
                                species: species,
                                label: _label(strings, species),
                                selected: species == _species,
                                onTap: () => _select(species),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('mascot_name'),
                        controller: _name,
                        maxLength: MascotProfile.maxNameLength,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          _nameEdited = true;
                          _selectionEdited = true;
                        },
                        onSubmitted: (_) => _continue(),
                        decoration: InputDecoration(
                          labelText: strings.mascotNameLabel,
                          counterText: '',
                          prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('mascot_continue'),
                        onPressed: _submitting ? null : _continue,
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
                        child: Text(
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
      ),
    );
  }

  static String _label(AppLocalizations strings, MascotSpecies species) =>
      switch (species) {
        MascotSpecies.crocodile => strings.mascotCrocodile,
        MascotSpecies.capybara => strings.mascotCapybara,
      };

  static String _traits(AppLocalizations strings, MascotSpecies species) =>
      switch (species) {
        MascotSpecies.crocodile => strings.mascotCrocodileTraits,
        MascotSpecies.capybara => strings.mascotCapybaraTraits,
      };
}

/// The chosen buddy standing on the grass of its scene, with a name tag.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.species,
    required this.controller,
    required this.name,
    required this.traits,
    required this.tapHint,
  });

  final MascotSpecies species;
  final MascotController controller;
  final TextEditingController name;
  final String traits;
  final String tapHint;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxHeight >= 220;
        final tagHeight = roomy ? 62.0 : 0.0;
        final size = [
          200.0,
          (box.maxHeight - tagHeight - 20) / MascotView.heightFactor,
          box.maxWidth * .55,
        ].reduce((a, b) => a < b ? a : b).clamp(0.0, 200.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: MascotView(
                key: ValueKey(species),
                species: species,
                size: size,
                controller: controller,
                interactive: true,
                semanticLabel: strings.mascotSemantic(name.text),
              ),
            ),
            if (roomy) ...[
              const SizedBox(height: 4),
              _NameTag(
                species: species,
                name: name,
                caption: '$traits  ·  $tapHint',
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

/// The buddy's name and personality on a pill over the grass.
class _NameTag extends StatelessWidget {
  const _NameTag({
    required this.species,
    required this.name,
    required this.caption,
  });

  final MascotSpecies species;
  final TextEditingController name;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: .92),
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: name,
            builder: (context, value, _) {
              final shown = value.text.trim().isEmpty
                  ? MascotProfile.defaultName(species)
                  : value.text.trim();
              return Text(
                shown,
                key: const Key('mascot_stage_name'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(
                  shown,
                  theme.textTheme.titleMediumBold,
                ),
              );
            },
          ),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.bodyStyleFor(
              caption,
              theme.textTheme.labelSmall?.copyWith(color: palette.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// One species choice, styled like the language cards that come next.
class _SpeciesTile extends StatelessWidget {
  const _SpeciesTile({
    super.key,
    required this.species,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MascotSpecies species;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.largeBorder,
          onTap: onTap,
          child: AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadii.largeBorder,
              border: Border.all(
                color: selected ? palette.brand : palette.outline,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      MascotView(species: species, size: 48, alive: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.bodyStyleFor(
                            label,
                            theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 6,
                    right: -4,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: RiksaMotion.resolve(
                        context,
                        RiksaMotion.standard,
                      ),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: palette.brand,
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
