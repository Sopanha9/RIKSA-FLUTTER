import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_achievement_image.dart';
import '../../../../core/widgets/riksa_rank_badge.dart';
import '../../../auth/data/auth_models.dart';
import '../../data/profile_models.dart';

class ProfilePalette {
  ProfilePalette._();

  static ProfilePaletteScope? _scope(BuildContext context) =>
      ProfilePaletteScope.maybeOf(context);

  static Color green(BuildContext context) =>
      _scope(context)?.accent ?? context.riksa.brand;
  static Color streak(BuildContext context) =>
      _scope(context)?.achievement ?? context.riksa.saffron;
  static Color xp(BuildContext context) =>
      _scope(context)?.achievement ?? context.riksa.saffron;

  static Color canvas(BuildContext context) =>
      _scope(context)?.canvas ?? Theme.of(context).scaffoldBackgroundColor;

  static Color panel(BuildContext context) =>
      _scope(context)?.panel ??
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color panelSoft(BuildContext context) =>
      _scope(context)?.panelSoft ??
      Theme.of(context).colorScheme.surfaceContainer;

  static Color border(BuildContext context) =>
      _scope(context)?.border ?? Theme.of(context).colorScheme.outline;

  static Color text(BuildContext context) =>
      _scope(context)?.text ?? Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) =>
      _scope(context)?.muted ?? Theme.of(context).colorScheme.onSurfaceVariant;

  static Color greenSoft(BuildContext context) =>
      _scope(context)?.accentSoft ??
      Theme.of(context).colorScheme.primaryContainer;

  static Color achievementSoft(BuildContext context) =>
      _scope(context)?.achievementSoft ?? AppColors.gamificationOrangeSoft;

  static Color aubergine(BuildContext context) =>
      _scope(context)?.aubergine ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppColors.editorialAubergineRaised
          : AppColors.editorialAubergine);

  static Color pink(BuildContext context) =>
      _scope(context)?.pink ?? AppColors.editorialPink;

  static Color pinkSoft(BuildContext context) =>
      _scope(context)?.pinkSoft ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppColors.violetDarkSoft
          : AppColors.editorialPinkSoft);

  static Color editorialSurface(BuildContext context) =>
      _scope(context)?.editorialSurface ??
      (Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainer
          : AppColors.editorialSurface);

  static Color onAubergine(BuildContext context) =>
      _scope(context)?.onAubergine ?? const Color(0xFFFFF8FC);
}

/// Lets an individual profile route opt into a coherent color system without
/// changing the palette used by the rest of the account experience.
class ProfilePaletteScope extends InheritedWidget {
  const ProfilePaletteScope({
    super.key,
    required this.canvas,
    required this.panel,
    required this.panelSoft,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.achievement,
    required this.achievementSoft,
    required this.aubergine,
    required this.pink,
    required this.pinkSoft,
    required this.editorialSurface,
    required this.onAubergine,
    required super.child,
  });

  factory ProfilePaletteScope.editorial({
    required BuildContext context,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.riksa;
    return ProfilePaletteScope(
      canvas: isDark ? palette.canvas : AppColors.editorialNeutralCanvas,
      panel: isDark ? palette.surface : AppColors.editorialNeutralSurface,
      panelSoft: isDark ? palette.surfaceRaised : AppColors.editorialField,
      border: isDark ? palette.outline : AppColors.editorialOutline,
      text: isDark ? palette.ink : AppColors.editorialInk,
      muted: isDark ? palette.inkMuted : AppColors.editorialMuted,
      accent: AppColors.editorialPink,
      accentSoft: isDark
          ? AppColors.violetDarkSoft
          : AppColors.editorialPinkSoft,
      achievement: AppColors.editorialPink,
      achievementSoft: isDark
          ? AppColors.violetDarkSoft
          : AppColors.editorialPinkSoft,
      aubergine: isDark
          ? AppColors.editorialAubergineRaised
          : AppColors.editorialAubergine,
      pink: AppColors.editorialPink,
      pinkSoft: isDark ? AppColors.violetDarkSoft : AppColors.editorialPinkSoft,
      editorialSurface: isDark
          ? palette.surface
          : AppColors.editorialNeutralSurface,
      onAubergine: const Color(0xFFFFF8FC),
      child: child,
    );
  }

  final Color canvas;
  final Color panel;
  final Color panelSoft;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color achievement;
  final Color achievementSoft;
  final Color aubergine;
  final Color pink;
  final Color pinkSoft;
  final Color editorialSurface;
  final Color onAubergine;

  static ProfilePaletteScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfilePaletteScope>();

  @override
  bool updateShouldNotify(ProfilePaletteScope oldWidget) =>
      canvas != oldWidget.canvas ||
      panel != oldWidget.panel ||
      panelSoft != oldWidget.panelSoft ||
      border != oldWidget.border ||
      text != oldWidget.text ||
      muted != oldWidget.muted ||
      accent != oldWidget.accent ||
      accentSoft != oldWidget.accentSoft ||
      achievement != oldWidget.achievement ||
      achievementSoft != oldWidget.achievementSoft ||
      aubergine != oldWidget.aubergine ||
      pink != oldWidget.pink ||
      pinkSoft != oldWidget.pinkSoft ||
      editorialSurface != oldWidget.editorialSurface ||
      onAubergine != oldWidget.onAubergine;
}

String readableProfileName(String value) => value
    .toLowerCase()
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

class RiksaProfileAvatar extends StatelessWidget {
  const RiksaProfileAvatar({
    super.key,
    required this.user,
    this.radius = 46,
    this.avatarPath,
    this.borderColor,
    this.ringColor,
    this.frameTier,
  });

  final AuthUser user;
  final double radius;
  final String? avatarPath;
  final Color? borderColor;
  final Color? ringColor;
  final String? frameTier;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    if (riksaAvatarFrameAssetPath(frameTier) != null) {
      return RiksaAvatarImage(
        value: avatarPath ?? user.avatarUrl,
        label: name,
        size: radius * 2,
        backgroundColor: ProfilePalette.panelSoft(context),
        foregroundColor: ProfilePalette.text(context),
        frameTier: frameTier,
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor ?? context.riksa.jadeSoft,
        border: Border.all(color: borderColor ?? context.riksa.brand, width: 2),
      ),
      child: RiksaAvatarImage(
        value: avatarPath ?? user.avatarUrl,
        label: name,
        size: (radius - 3) * 2,
        backgroundColor: ProfilePalette.panelSoft(context),
        foregroundColor: ProfilePalette.text(context),
      ),
    );
  }
}

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.mediumBorder,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Material(
        color: ProfilePalette.panel(context).withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
          side: ProfilePaletteScope.maybeOf(context) == null
              ? BorderSide.none
              : BorderSide(
                  color: ProfilePalette.border(context).withValues(alpha: 0.5),
                ),
        ),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    ),
  );
}

enum ProfileTab { posts, achievements, rank }

/// One icon + label pair in the metadata line under the bio.
class ProfileMetaItem {
  const ProfileMetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// One bold-value + muted-label pair in the counts line.
///
/// This is where X puts following/followers. Riksa has no follow graph, so the
/// slot carries the learning numbers instead, in the same typographic
/// treatment rather than as a row of big-number tiles.
class ProfileCountItem {
  const ProfileCountItem({
    required this.value,
    required this.label,
    this.itemKey,
  });

  final String value;
  final String label;
  final Key? itemKey;
}

/// Left-aligned identity block modelled on the X profile layout: banner,
/// avatar overlapping its leading edge, actions on the trailing edge, then
/// name, handle, bio, metadata and counts as one typographic stack.
class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    super.key,
    required this.cover,
    required this.avatar,
    required this.displayName,
    required this.username,
    this.bio,
    this.isVerified = false,
    this.verifiedKey = const ValueKey('public-verification-badge'),
    this.actions = const [],
    this.metadata = const [],
    this.counts = const [],
    this.countsKey,
    this.footer,
  });

  final Widget cover;
  final Widget avatar;
  final String displayName;
  final String username;
  final String? bio;
  final bool isVerified;

  /// Identifies the badge per screen; both profiles render the same mark.
  final Key verifiedKey;

  /// Trailing controls on the action line: edit, share, settings.
  final List<Widget> actions;
  final List<ProfileMetaItem> metadata;
  final List<ProfileCountItem> counts;
  final Key? countsKey;

  /// Optional block below the counts line. Carries the tier and XP progress.
  final Widget? footer;

  static const double coverHeight = 132;
  static const double _avatarOverhang = 34;
  static const double _actionRowHeight = 44;

  @override
  Widget build(BuildContext context) {
    final trimmedBio = bio?.trim();
    final handle = username.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(height: coverHeight, width: double.infinity, child: cover),
            PositionedDirectional(
              start: 2,
              bottom: -_avatarOverhang,
              child: avatar,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          // With no actions the row still has to clear the avatar's overhang,
          // so it shrinks to that rather than collapsing onto the name.
          height: actions.isEmpty ? _avatarOverhang + 6 : _actionRowHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                actions[index],
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(
                  displayName,
                  TextStyle(
                    color: ProfilePalette.text(context),
                    fontSize: 20,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              Icon(
                key: verifiedKey,
                Icons.verified_rounded,
                color: ProfilePalette.green(context),
                size: 19,
              ),
            ],
          ],
        ),
        if (handle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '@$handle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProfilePalette.muted(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (trimmedBio?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            trimmedBio!,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.bodyStyleFor(
              trimmedBio,
              TextStyle(
                color: ProfilePalette.text(context),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ),
        ],
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final item in metadata)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 15,
                      color: ProfilePalette.muted(context),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: ProfilePalette.muted(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (counts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            key: countsKey,
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final item in counts)
                Row(
                  key: item.itemKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        color: ProfilePalette.text(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: ProfilePalette.muted(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ],
    );
  }
}

/// Keeps every sliver on the same measure as the pinned tab strip.
Widget centeredProfileColumn(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: child,
  ),
);

/// Square icon control on the header action line.
class ProfileIconAction extends StatelessWidget {
  const ProfileIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      minimumSize: const Size.square(44),
      backgroundColor: ProfilePalette.editorialSurface(context),
      foregroundColor: ProfilePalette.text(context),
      side: BorderSide(color: ProfilePalette.border(context)),
    ),
    icon: Icon(icon, size: 19),
  );
}

/// The rank ladder uses collectible badges with a ring on the current tier
/// and locks on tiers still ahead. Band progress is shown separately below.
///
/// It answers the three questions the roadmap answers: where I started, where
/// I am, where this ends. A bare percentage answers none of them.
class ProfileTierRail extends StatelessWidget {
  const ProfileTierRail({
    super.key,
    required this.tiers,
    required this.currentIndex,
    required this.startLabel,
    required this.endLabel,
  });

  final List<String> tiers;
  final int currentIndex;
  final String startLabel;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final reached = ProfilePalette.text(context);
    final ahead = ProfilePalette.muted(context).withValues(alpha: .3);

    final segments = <Widget>[];
    for (var i = 0; i < tiers.length; i++) {
      if (i > 0) {
        // Segments are climbed or not climbed. How far through the current
        // one the learner is belongs to the bar below, said once.
        segments.add(
          Expanded(
            child: _RailSegment(
              climbed: i <= currentIndex,
              climbedColor: reached,
              aheadColor: ahead,
            ),
          ),
        );
      }
      segments.add(
        _RailNode(
          tier: tiers[i],
          state: i < currentIndex
              ? _NodeState.reached
              : i == currentIndex
              ? _NodeState.current
              : i == tiers.length - 1
              ? _NodeState.destination
              : _NodeState.ahead,
          reachedColor: reached,
          markerColor: reached,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 44, child: Row(children: segments)),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RailEndLabel(
              label: startLabel,
              color: ProfilePalette.muted(context),
            ),
            _RailEndLabel(label: endLabel, color: ProfilePalette.text(context)),
          ],
        ),
      ],
    );
  }
}

class _RailEndLabel extends StatelessWidget {
  const _RailEndLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: color,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: .3,
    ),
  );
}

enum _NodeState { reached, current, destination, ahead }

class _RailNode extends StatelessWidget {
  const _RailNode({
    required this.tier,
    required this.state,
    required this.reachedColor,
    required this.markerColor,
  });

  final String tier;
  final _NodeState state;
  final Color reachedColor;
  final Color markerColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: readableProfileName(tier),
    selected: state == _NodeState.current,
    child: Container(
      width: 36,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: AppRadii.smallBorder,
        border: state == _NodeState.current
            ? Border.all(color: markerColor, width: 2)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RiksaRankBadge(tier: tier, size: 32),
          if (state == _NodeState.ahead || state == _NodeState.destination)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.lock_rounded, size: 12, color: reachedColor),
            ),
        ],
      ),
    ),
  );
}

class _RailSegment extends StatelessWidget {
  const _RailSegment({
    required this.climbed,
    required this.climbedColor,
    required this.aheadColor,
  });

  final bool climbed;
  final Color climbedColor;
  final Color aheadColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Container(
      height: 3,
      decoration: BoxDecoration(
        color: climbed ? climbedColor : aheadColor,
        borderRadius: AppRadii.fullBorder,
      ),
    ),
  );
}

/// The tier block on someone else's profile.
///
/// It shows position on the ladder but no band progress: a reader does not
/// need another learner's exact XP-to-next, only where they stand.
class ProfileTierPanel extends StatelessWidget {
  const ProfileTierPanel({
    super.key,
    required this.tier,
    required this.totalXpLabel,
  });

  final String tier;
  final String totalXpLabel;

  @override
  Widget build(BuildContext context) {
    final ladderIndex = profileTierLadder.indexOf(tier.toUpperCase());
    return ProfilePanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skipped for a tier this build does not know, such as the server's
          // "STARTER" placeholder, rather than drawing an unmarked rail.
          if (ladderIndex >= 0) ...[
            ProfileTierRail(
              key: const ValueKey('public-tier-rail'),
              tiers: profileTierLadder,
              currentIndex: ladderIndex,
              startLabel: ladderIndex == 0
                  ? ''
                  : readableProfileName(profileTierLadder.first),
              endLabel: ladderIndex == profileTierLadder.length - 1
                  ? ''
                  : readableProfileName(profileTierLadder.last),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              RiksaRankBadge(tier: tier, size: 44),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  readableProfileName(tier),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProfilePalette.text(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                totalXpLabel,
                style: TextStyle(
                  color: ProfilePalette.muted(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Underline tab strip, sized to sit in a pinned sliver header.
class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.postsLabel,
    required this.achievementsLabel,
    required this.rankLabel,
  });

  final ProfileTab selected;
  final ValueChanged<ProfileTab> onSelected;
  final String postsLabel;
  final String achievementsLabel;
  final String rankLabel;

  /// Base height. The pinned header and strip grow together for larger text.
  static const double height = 58;

  static double heightFor(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(12.5) * 1.2 + 24).clamp(
        height,
        double.infinity,
      );

  @override
  Widget build(BuildContext context) => SizedBox(
    height: heightFor(context),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ProfilePalette.canvas(context),
        border: Border(
          bottom: BorderSide(color: ProfilePalette.border(context)),
        ),
      ),
      child: _strip(context),
    ),
  );
  Widget _strip(BuildContext context) {
    final scroll = MediaQuery.textScalerOf(context).scale(12.5) > 16.25;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (tab, label, key) in [
          (ProfileTab.posts, postsLabel, 'profile-posts-tab'),
          (
            ProfileTab.achievements,
            achievementsLabel,
            'profile-achievements-tab',
          ),
          (ProfileTab.rank, rankLabel, 'profile-rank-tab'),
        ])
          _ProfileTabButton(
            key: ValueKey(key),
            label: label,
            selected: selected == tab,
            onTap: () => onSelected(tab),
            expand: !scroll,
          ),
      ],
    );
    return scroll
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: row)
        : row;
  }
}

/// Pins [ProfileTabs] under the identity header while content scrolls beneath.
class ProfileTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const ProfileTabsHeaderDelegate({
    required this.tabs,
    required this.color,
    this.extent = ProfileTabs.height,
  });

  final ProfileTabs tabs;
  final double extent;

  /// Painted behind the strip so scrolled content never shows through.
  final Color color;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: color,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: tabs,
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(ProfileTabsHeaderDelegate oldDelegate) =>
      oldDelegate.tabs.selected != tabs.selected ||
      oldDelegate.tabs.postsLabel != tabs.postsLabel ||
      oldDelegate.tabs.achievementsLabel != tabs.achievementsLabel ||
      oldDelegate.tabs.rankLabel != tabs.rankLabel ||
      oldDelegate.color != color ||
      oldDelegate.extent != extent;
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: expand ? 6 : 14),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: expand ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? ProfilePalette.text(context)
                        : ProfilePalette.muted(context),
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            height: 3,
            width: selected ? 58 : 0,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ProfilePalette.pink(context)
                  : ProfilePalette.aubergine(context),
              borderRadius: AppRadii.fullBorder,
            ),
          ),
        ],
      ),
    );
    return expand ? Expanded(child: button) : IntrinsicWidth(child: button);
  }
}

/// Content-sized cards switch to one column when width or text size needs it.
class ProfileAchievementGrid extends StatelessWidget {
  const ProfileAchievementGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = constraints.maxWidth >= 316 && textScale <= 1.3 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var index = 0; index < itemCount; index++)
            SizedBox(width: width, child: itemBuilder(context, index)),
        ],
      );
    },
  );
}

class ProfileAchievementTile extends StatelessWidget {
  const ProfileAchievementTile({
    super.key,
    required this.name,
    required this.description,
    this.iconUrl,
    this.trailingLabel,
  });

  final String name;
  final String description;
  final String? iconUrl;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RiksaAchievementImage(iconUrl: iconUrl),
            const SizedBox(width: 8),
            if (trailingLabel?.isNotEmpty == true)
              Expanded(
                child: Text(
                  trailingLabel!,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: ProfilePalette.xp(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            color: ProfilePalette.muted(context),
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class ProfileRankCard extends StatelessWidget {
  const ProfileRankCard({
    super.key,
    required this.label,
    required this.rank,
    required this.unrankedLabel,
    this.icon,
    this.iconWidget,
    this.trailing,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final int? rank;
  final String unrankedLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ProfilePalette.greenSoft(context),
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                iconWidget ??
                Icon(icon, color: ProfilePalette.green(context), size: 23),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ProfilePalette.muted(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                rank != null && rank! > 0 ? '#$rank' : unrankedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ProfilePalette.text(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

enum ProfileRankIconKind { country, province }

class ProfileRankPixelIcon extends StatelessWidget {
  const ProfileRankPixelIcon({super.key, required this.kind, this.size = 30});

  final ProfileRankIconKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ProfileRankPixelIconPainter(
        kind: kind,
        color: ProfilePalette.green(context),
        accent: ProfilePalette.aubergine(context),
      ),
    ),
  );
}

class _ProfileRankPixelIconPainter extends CustomPainter {
  const _ProfileRankPixelIconPainter({
    required this.kind,
    required this.color,
    required this.accent,
  });

  final ProfileRankIconKind kind;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 18;
    final outline = Paint()
      ..color = Color.lerp(color, Colors.black, .28)!
      ..style = PaintingStyle.fill;
    final main = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = color.withValues(alpha: .24)
      ..style = PaintingStyle.fill;
    final purple = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final white = Paint()
      ..color = Colors.white.withValues(alpha: .88)
      ..style = PaintingStyle.fill;

    void px(Paint paint, int x, int y, [int w = 1, int h = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    switch (kind) {
      case ProfileRankIconKind.country:
        px(soft, 3, 3, 12, 12);
        px(outline, 5, 2, 8, 1);
        px(outline, 3, 4, 12, 1);
        px(outline, 2, 6, 14, 6);
        px(outline, 3, 12, 12, 2);
        px(outline, 5, 14, 8, 1);
        px(main, 5, 3, 8, 1);
        px(main, 4, 5, 10, 2);
        px(main, 3, 7, 12, 4);
        px(main, 4, 11, 10, 2);
        px(main, 6, 13, 6, 1);
        px(white, 8, 4, 2, 10);
        px(white, 4, 8, 10, 2);
        px(purple, 6, 5, 2, 2);
        px(purple, 10, 10, 2, 2);
      case ProfileRankIconKind.province:
        px(soft, 4, 3, 10, 12);
        px(outline, 6, 2, 6, 1);
        px(outline, 4, 4, 10, 1);
        px(outline, 3, 6, 12, 5);
        px(outline, 4, 11, 10, 2);
        px(outline, 6, 13, 6, 2);
        px(outline, 8, 15, 2, 1);
        px(main, 6, 3, 6, 1);
        px(main, 5, 5, 8, 1);
        px(main, 4, 6, 10, 4);
        px(main, 5, 10, 8, 2);
        px(main, 7, 12, 4, 2);
        px(main, 8, 14, 2, 1);
        px(white, 7, 6, 4, 4);
        px(purple, 8, 7, 2, 2);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileRankPixelIconPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent;
}

class ProfileLoadingState extends StatelessWidget {
  const ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: CircularProgressIndicator(color: ProfilePalette.green(context)),
    ),
  );
}

class ProfileEmptyPanel extends StatelessWidget {
  const ProfileEmptyPanel({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: ProfilePalette.green(context), size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: ProfilePalette.muted(context)),
          ),
        ],
      ),
    ),
  );
}

class ProfileErrorPanel extends StatelessWidget {
  const ProfileErrorPanel({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
    this.retryButtonKey,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final IconData icon;
  final Key? retryButtonKey;

  @override
  Widget build(BuildContext context) => ProfilePanel(
    child: Column(
      children: [
        Icon(icon, color: ProfilePalette.green(context), size: 34),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: ProfilePalette.muted(context)),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          key: retryButtonKey,
          onPressed: onRetry,
          child: Text(retryLabel),
        ),
      ],
    ),
  );
}
