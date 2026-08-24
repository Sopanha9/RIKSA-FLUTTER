import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/auth_models.dart';
import '../providers/auth_provider.dart';

class ProvinceSelectScreen extends ConsumerStatefulWidget {
  const ProvinceSelectScreen({super.key});

  @override
  ConsumerState<ProvinceSelectScreen> createState() =>
      _ProvinceSelectScreenState();
}

class _ProvinceSelectScreenState extends ConsumerState<ProvinceSelectScreen> {
  final _searchController = TextEditingController();
  String? _selectedId;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = ref.read(localeProvider).pendingProvinceId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final provinceId = _selectedId;
    if (provinceId == null || _saving) return;
    setState(() => _saving = true);
    final success = await ref
        .read(authProvider.notifier)
        .saveProvinceSelection(provinceId);
    if (!mounted) return;
    if (!success) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.provinceSaveFailed),
        ),
      );
      return;
    }
    final authenticated = ref.read(authProvider) is Authenticated;
    context.go(authenticated ? '/home' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final provinces = ref.watch(provinceOptionsProvider);

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.riksa.blushSoft,
                  borderRadius: AppRadii.largeBorder,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.selectProvinceTitle,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 9),
              Text(
                l10n.selectProvinceSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              RiksaSearchField(
                key: const Key('province_search'),
                controller: _searchController,
                hintText: l10n.searchProvince,
                onChanged: (value) => setState(() => _query = value.trim()),
                trailing: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: provinces.when(
                  loading: () => const RiksaStateView(
                    title: 'Loading provinces',
                    body: 'Preparing local learning options.',
                    loading: true,
                  ),
                  error: (error, stackTrace) => _ProvinceError(
                    message: l10n.provinceLoadFailed,
                    retryLabel: l10n.tryAgain,
                    onRetry: () => ref.invalidate(provinceOptionsProvider),
                  ),
                  data: (items) {
                    final filtered = items.where((province) {
                      final query = _query.toLowerCase();
                      return query.isEmpty ||
                          province.nameLatin.toLowerCase().contains(query) ||
                          province.nameKhmer.contains(_query);
                    }).toList();
                    if (filtered.isEmpty) {
                      return RiksaStateView(
                        title: l10n.noProvinceResults,
                        body: l10n.searchProvince,
                        icon: Icons.search_off_rounded,
                      );
                    }
                    return ListView.separated(
                      key: const Key('province_list'),
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final province = filtered[index];
                        return _ProvinceTile(
                          province: province,
                          languageCode: languageCode,
                          selected: _selectedId == province.id,
                          onTap: () =>
                              setState(() => _selectedId = province.id),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('province_continue'),
                  onPressed: _selectedId == null || _saving ? null : _continue,
                  child: _saving
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            color: context.riksa.canvas,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.continueLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

class _ProvinceTile extends StatelessWidget {
  const _ProvinceTile({
    required this.province,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  final ProvinceOption province;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primaryName = languageCode == 'km'
        ? province.nameKhmer
        : province.nameLatin;
    final secondaryName = languageCode == 'km'
        ? province.nameLatin
        : province.nameKhmer;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.extraLargeBorder,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.riksa.jadeSoft : context.riksa.surface,
            borderRadius: AppRadii.extraLargeBorder,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondaryName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProvinceError extends StatelessWidget {
  const _ProvinceError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
