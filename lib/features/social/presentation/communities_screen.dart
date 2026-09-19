import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';

/// Learning groups to discover and join, and the ones already joined.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});
  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  List<SocialCategory>? _items;
  bool _failed = false;
  bool _mineOnly = false;
  String _query = '';
  final _pending = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final value = await ref.read(socialApiProvider).categories();
      if (mounted) setState(() => _items = value);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle(SocialCategory item) async {
    if (_pending.contains(item.id)) return;
    setState(() => _pending.add(item.id));
    try {
      final updated = await ref
          .read(socialApiProvider)
          .setCategoryJoined(item.id, joined: !item.joined);
      if (!mounted) return;
      setState(() {
        final index = _items!.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) _items![index] = updated;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)),
          );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final items = (_items ?? const <SocialCategory>[])
        .where((item) => !_mineOnly || item.joined)
        .where(
          (item) =>
              _query.isEmpty ||
              item.name.toLowerCase().contains(_query) ||
              (item.description ?? '').toLowerCase().contains(_query),
        )
        .toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        leading: IconButton(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.menuCommunities,
          style: RiksaTypography.titleStyleFor(
            l10n.menuCommunities,
            theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _CommunityTabs(
              mineOnly: _mineOnly,
              onChanged: (value) => setState(() => _mineOnly = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: RiksaSearchBar(
              key: const ValueKey('communities-search'),
              hintText: l10n.communitiesSearchHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: _items == null
                ? Center(
                    child: _failed
                        ? IllustratedEmptyState(
                            title: l10n.communitiesUnavailable,
                            body: l10n.communitiesLoadFailed,
                            actionLabel: l10n.tryAgain,
                            onAction: _load,
                          )
                        : const CircularProgressIndicator(),
                  )
                : items.isEmpty
                ? IllustratedEmptyState(
                    title: _mineOnly
                        ? l10n.communitiesMine
                        : l10n.noSearchResults,
                    body: _mineOnly
                        ? l10n.communitiesNoneJoined
                        : l10n.communitiesSearchHint,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CommunityRow(
                        item: items[index],
                        busy: _pending.contains(items[index].id),
                        onToggle: () => _toggle(items[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs({required this.mineOnly, required this.onChanged});

  final bool mineOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    final selectedFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.54);
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    Widget tab(String label, bool selected, VoidCallback onTap, String key) =>
        Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            child: InkWell(
              key: ValueKey(key),
              onTap: onTap,
              borderRadius: AppRadii.fullBorder,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    label,
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? palette.brand : palette.inkMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.fullBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: AppRadii.fullBorder,
              border: Border.all(color: glassBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      start: mineOnly ? tabWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectedFill,
                          borderRadius: AppRadii.fullBorder,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.ink.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        tab(
                          l10n.communitiesDiscover,
                          !mineOnly,
                          () => onChanged(false),
                          'communities-discover-tab',
                        ),
                        tab(
                          l10n.communitiesMine,
                          mineOnly,
                          () => onChanged(true),
                          'communities-mine-tab',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.item,
    required this.busy,
    required this.onToggle,
  });

  final SocialCategory item;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final locale = Localizations.localeOf(context).languageCode;
    final members = l10n.communityMembers(
      NumberFormat.compact(locale: locale).format(item.memberCount),
    );

    return Container(
      key: ValueKey('community-${item.id}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          _CommunityPixelIcon(name: item.name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    item.name,
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  members,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    members,
                    theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          item.joined
              ? OutlinedButton(
                  key: ValueKey('community-toggle-${item.id}'),
                  onPressed: busy ? null : onToggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(l10n.communityJoined),
                )
              : FilledButton(
                  key: ValueKey('community-toggle-${item.id}'),
                  onPressed: busy ? null : onToggle,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(l10n.communityJoin),
                ),
        ],
      ),
    );
  }
}

class _CommunityPixelIcon extends StatelessWidget {
  const _CommunityPixelIcon({required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _CommunityPixelIconPainter(name)),
  );
}

enum _CommunityIconKind {
  biology,
  chemistry,
  computer,
  english,
  history,
  general,
}

class _CommunityPixelIconPainter extends CustomPainter {
  const _CommunityPixelIconPainter(this.name);

  final String name;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final kind = _kindFor(name);
    final palette = _CommunityIconPalette.forKind(kind);
    canvas.drawRRect(_rr(5, 5, 54, 54, 13), _fill(palette.bg));
    canvas.drawRect(
      const Rect.fromLTWH(11, 11, 4, 4),
      _fill(Colors.white.withValues(alpha: .78)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(17, 8, 5, 5),
      _fill(Colors.white.withValues(alpha: .62)),
    );

    switch (kind) {
      case _CommunityIconKind.biology:
        _paintLeaf(canvas, palette);
      case _CommunityIconKind.chemistry:
        _paintFlask(canvas, palette);
      case _CommunityIconKind.computer:
        _paintCode(canvas, palette);
      case _CommunityIconKind.english:
        _paintCap(canvas, palette);
      case _CommunityIconKind.history:
        _paintScroll(canvas, palette);
      case _CommunityIconKind.general:
        _paintChat(canvas, palette);
    }
  }

  static _CommunityIconKind _kindFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('bio') || value.contains('ជីវ')) {
      return _CommunityIconKind.biology;
    }
    if (value.contains('chem') || value.contains('គីមី')) {
      return _CommunityIconKind.chemistry;
    }
    if (value.contains('computer') ||
        value.contains('tech') ||
        value.contains('កុំព្យូទ័រ')) {
      return _CommunityIconKind.computer;
    }
    if (value.contains('english') || value.contains('អង់គ្លេស')) {
      return _CommunityIconKind.english;
    }
    if (value.contains('history') ||
        value.contains('heritage') ||
        value.contains('ប្រវត្តិ')) {
      return _CommunityIconKind.history;
    }
    return _CommunityIconKind.general;
  }

  void _paintLeaf(Canvas c, _CommunityIconPalette p) {
    c.drawOval(const Rect.fromLTWH(20, 20, 28, 24), _fill(p.main));
    c.drawOval(const Rect.fromLTWH(20, 20, 28, 24), _stroke(p.edge, 3));
    c.drawArc(
      const Rect.fromLTWH(17, 16, 34, 34),
      3.2,
      2.3,
      false,
      _stroke(p.bg, 8),
    );
    c.drawLine(const Offset(24, 43), const Offset(47, 18), _stroke(p.edge, 3));
    c.drawLine(const Offset(29, 36), const Offset(40, 28), _stroke(p.soft, 2));
  }

  void _paintFlask(Canvas c, _CommunityIconPalette p) {
    c.drawRect(const Rect.fromLTWH(27, 16, 10, 6), _fill(p.main));
    c.drawRect(const Rect.fromLTWH(30, 22, 4, 12), _fill(p.light));
    final flask = Path()
      ..moveTo(22, 33)
      ..lineTo(42, 33)
      ..lineTo(50, 50)
      ..lineTo(14, 50)
      ..close();
    c.drawPath(flask, _fill(p.main));
    c.drawPath(flask, _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(21, 42, 24, 5), _fill(p.soft));
  }

  void _paintCode(Canvas c, _CommunityIconPalette p) {
    c.drawRRect(_rr(15, 18, 34, 25, 4), _fill(p.light));
    c.drawRRect(_rr(15, 18, 34, 25, 4), _stroke(p.edge, 3));
    c.drawLine(const Offset(26, 25), const Offset(20, 31), _stroke(p.main, 3));
    c.drawLine(const Offset(20, 31), const Offset(26, 37), _stroke(p.main, 3));
    c.drawLine(const Offset(38, 25), const Offset(44, 31), _stroke(p.main, 3));
    c.drawLine(const Offset(44, 31), const Offset(38, 37), _stroke(p.main, 3));
    c.drawLine(const Offset(35, 25), const Offset(29, 38), _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(23, 45, 18, 5), _fill(p.main));
  }

  void _paintCap(Canvas c, _CommunityIconPalette p) {
    final cap = Path()
      ..moveTo(13, 28)
      ..lineTo(32, 18)
      ..lineTo(51, 28)
      ..lineTo(32, 39)
      ..close();
    c.drawPath(cap, _fill(p.main));
    c.drawPath(cap, _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(22, 37, 20, 9), _fill(p.soft));
    c.drawRect(const Rect.fromLTWH(22, 37, 20, 9), _stroke(p.edge, 2));
    c.drawLine(const Offset(48, 30), const Offset(48, 43), _stroke(p.edge, 2));
    c.drawRect(const Rect.fromLTWH(45, 43, 6, 5), _fill(p.edge));
  }

  void _paintScroll(Canvas c, _CommunityIconPalette p) {
    c.drawRect(const Rect.fromLTWH(18, 19, 28, 29), _fill(p.light));
    c.drawRect(const Rect.fromLTWH(18, 19, 28, 29), _stroke(p.edge, 3));
    c.drawOval(const Rect.fromLTWH(14, 17, 10, 10), _fill(p.soft));
    c.drawOval(const Rect.fromLTWH(40, 40, 10, 10), _fill(p.soft));
    for (final y in const [27.0, 34.0, 41.0]) {
      c.drawLine(Offset(24, y), Offset(40, y), _stroke(p.main, 2));
    }
  }

  void _paintChat(Canvas c, _CommunityIconPalette p) {
    c.drawRRect(_rr(16, 20, 32, 22, 5), _fill(p.main));
    c.drawRRect(_rr(16, 20, 32, 22, 5), _stroke(p.edge, 3));
    final tail = Path()
      ..moveTo(25, 40)
      ..lineTo(25, 49)
      ..lineTo(35, 41)
      ..close();
    c.drawPath(tail, _fill(p.main));
    c.drawPath(tail, _stroke(p.edge, 2));
    for (final x in const [24.0, 31.0, 38.0]) {
      c.drawRect(Rect.fromLTWH(x, 29, 4, 4), _fill(p.light));
    }
  }

  static Paint _fill(Color color) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  bool shouldRepaint(covariant _CommunityPixelIconPainter oldDelegate) =>
      oldDelegate.name != name;
}

class _CommunityIconPalette {
  const _CommunityIconPalette({
    required this.bg,
    required this.edge,
    required this.main,
    required this.soft,
    required this.light,
  });

  final Color bg;
  final Color edge;
  final Color main;
  final Color soft;
  final Color light;

  static _CommunityIconPalette forKind(_CommunityIconKind kind) =>
      switch (kind) {
        _CommunityIconKind.biology => const _CommunityIconPalette(
          bg: Color(0xFFE0F4CF),
          edge: Color(0xFF2F5629),
          main: Color(0xFF469140),
          soft: Color(0xFF8BC55E),
          light: Color(0xFFECFFF0),
        ),
        _CommunityIconKind.chemistry => const _CommunityIconPalette(
          bg: Color(0xFFE9DEFF),
          edge: Color(0xFF4A2B8E),
          main: Color(0xFF8456EE),
          soft: Color(0xFFBEA4FF),
          light: Color(0xFFF5EEFF),
        ),
        _CommunityIconKind.computer => const _CommunityIconPalette(
          bg: Color(0xFFD6F2E9),
          edge: Color(0xFF19564D),
          main: Color(0xFF238F7A),
          soft: Color(0xFF8EDBC7),
          light: Color(0xFFEFFFFA),
        ),
        _CommunityIconKind.english => const _CommunityIconPalette(
          bg: Color(0xFFFFEDC6),
          edge: Color(0xFF9A6700),
          main: Color(0xFFD99A14),
          soft: Color(0xFFFFCE62),
          light: Color(0xFFFFF7E6),
        ),
        _CommunityIconKind.history => const _CommunityIconPalette(
          bg: Color(0xFFFFE6D6),
          edge: Color(0xFF824018),
          main: Color(0xFFC16A2D),
          soft: Color(0xFFE9A160),
          light: Color(0xFFFFF4EA),
        ),
        _CommunityIconKind.general => const _CommunityIconPalette(
          bg: Color(0xFFFFEDC6),
          edge: Color(0xFF9A6700),
          main: Color(0xFFD99A14),
          soft: Color(0xFFFFCE62),
          light: Color(0xFFFFF7E6),
        ),
      };
}
