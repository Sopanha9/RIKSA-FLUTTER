import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/riksa_logo.dart';
import '../../../data/provinces_km.dart';

/// Province selection screen: shown after the user picks a language.
/// Khmer-first: the picker lists all 25 provinces with both Khmer and
/// English names. The selected province is stored and compared later.
class ProvinceSelectScreen extends ConsumerStatefulWidget {
  const ProvinceSelectScreen({super.key});

  @override
  ConsumerState<ProvinceSelectScreen> createState() =>
      _ProvinceSelectScreenState();
}

class _ProvinceSelectScreenState extends ConsumerState<ProvinceSelectScreen> {
  Province? _selected;
  bool _isKhmer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isKhmer = ref.read(localeProvider).languageCode == 'km';
  }

  Future<void> _continue() async {
    if (_selected == null) return;
    // TODO: persist selected province if needed (e.g. via a provider/prefs).
    if (mounted) context.go('/auth/login');
  }

  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<Province>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProvincePickerSheet(isKhmer: _isKhmer),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [RiksaLogo(fontSize: 32)],
              ),
              const Spacer(flex: 1),

              // Heading
              Text(
                _isKhmer ? 'ជ្រើសរើសខេត្ត' : 'Select your province',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isKhmer
                    ? 'សូមជ្រើសរើសខេត្តដែលអ្នកកំពុងរស់នៅ'
                    : 'Choose the province you live in',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 48),

              // Search-select field
              _ProvinceField(
                selected: _selected,
                isKhmer: _isKhmer,
                onTap: _openPicker,
              ),

              const Spacer(flex: 2),

              // Continue button — 213A64 background, white text
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213A64),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF213A64).withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isKhmer ? 'បន្ត' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable card showing the currently selected province, or a placeholder.
class _ProvinceField extends StatelessWidget {
  const _ProvinceField({
    required this.selected,
    required this.isKhmer,
    required this.onTap,
  });

  final Province? selected;
  final bool isKhmer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? const Color(0xFF213A64)
                  : const Color(0xFFE0DCD3),
              width: hasSelection ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: hasSelection
                    ? const Color(0xFF213A64)
                    : const Color(0xFF8A8A8A),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSelection) ...[
                      Text(
                        isKhmer ? selected!.km : selected!.en,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isKhmer ? selected!.en : selected!.km,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ] else
                      Text(
                        isKhmer ? 'ស្វែងរកខេត្ត...' : 'Search province...',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8A8A8A),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet with a search field and the list of 25 provinces.
class _ProvincePickerSheet extends StatefulWidget {
  const _ProvincePickerSheet({required this.isKhmer});

  final bool isKhmer;

  @override
  State<_ProvincePickerSheet> createState() => _ProvincePickerSheetState();
}

class _ProvincePickerSheetState extends State<_ProvincePickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Province> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return provincesKm;
    return provincesKm.where((p) {
      return p.km.contains(_query.trim()) ||
          p.en.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DCD3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.isKhmer ? 'ស្វែងរកខេត្ត...' : 'Search province...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8A8A)),
                  filled: true,
                  fillColor: const Color(0xFFF5F1EB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: Color(0xFFE0DCD3),
                ),
                itemBuilder: (context, index) {
                  final p = list[index];
                  return ListTile(
                    title: Text(
                      widget.isKhmer ? p.km : p.en,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Text(
                      widget.isKhmer ? p.en : p.km,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF8A8A8A)),
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              ),
            ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No province found',
                  style: TextStyle(color: Color(0xFF8A8A8A)),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}