import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/riksa_logo.dart';

/// Language selection screen: two cards stacked vertically — English on top,
/// Khmer below. User taps a card to select it, then taps "Select" to confirm.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  String? _selected; // 'en' or 'km', null = nothing selected yet

  Future<void> _confirmSelection() async {
    if (_selected == null) return;
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected!));
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Top bar: logo
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [RiksaLogo(fontSize: 32)],
              ),
              const Spacer(flex: 1),

              // Heading
              Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F1419),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'ជ្រើសរើសភាសារបស់អ្នក',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF536471),
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 48),

              // Two cards stacked vertically
              _LanguageCard(
                flagAsset: 'assets/images/logos/Flag_of_the_United_Kingdom.svg.png',
                languageName: 'English',
                languageNameNative: 'English',
                isSelected: _selected == 'en',
                onTap: () => setState(() => _selected = 'en'),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                flagAsset: 'assets/images/logos/Flag_of_Cambodia.svg',
                languageName: 'Khmer',
                languageNameNative: 'ខ្មែរ',
                isSelected: _selected == 'km',
                onTap: () => setState(() => _selected = 'km'),
              ),

              const Spacer(flex: 2),

              // Select button — disabled until a language is picked
              ElevatedButton(
                onPressed: _selected == null ? null : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Select'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatefulWidget {
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
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _tapped = true),
      onTapUp: (_) => setState(() => _tapped = false),
      onTapCancel: () => setState(() => _tapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        transform: _tapped
            ? Matrix4.diagonal3Values(0.97, 0.97, 1.0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF22C55E)
                : const Color(0xFFCFD9DE),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Flag image (SVG or PNG)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 36,
                child: _buildFlagImage(),
              ),
            ),
            const SizedBox(width: 20),
            // Language names
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.languageName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1419),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.languageNameNative,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF536471),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCFD9DE),
                  width: 2,
                ),
                color: selected ? const Color(0xFF22C55E) : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagImage() {
    final asset = widget.flagAsset;
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(asset, fit: BoxFit.cover);
    }
    return Image.asset(asset, fit: BoxFit.cover);
  }
}
