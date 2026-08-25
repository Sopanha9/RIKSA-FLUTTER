import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../auth/data/auth_models.dart';

class ProfilePalette {
  ProfilePalette._();

  static Color green(BuildContext context) => context.riksa.jade;
  static Color streak(BuildContext context) => context.riksa.saffron;
  static Color xp(BuildContext context) => context.riksa.saffron;

  static Color canvas(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color panel(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color panelSoft(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color greenSoft(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color aubergine(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.editorialAubergineRaised
      : AppColors.editorialAubergine;

  static Color pink(BuildContext context) => AppColors.editorialPink;

  static Color pinkSoft(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF4A253D)
      : AppColors.editorialPinkSoft;

  static Color editorialSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surfaceContainer
      : AppColors.editorialSurface;

  static Color onAubergine(BuildContext context) => const Color(0xFFFFF8FC);
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
  });

  final AuthUser user;
  final double radius;
  final String? avatarPath;
  final Color? borderColor;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor ?? context.riksa.jadeSoft,
        border: Border.all(color: borderColor ?? context.riksa.jade, width: 2),
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
  Widget build(BuildContext context) => Material(
    color: ProfilePalette.panel(context),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding ?? const EdgeInsets.all(18), child: child),
  );
}

enum ProfileTab { posts, achievements, rank }

class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    super.key,
    required this.cover,
    required this.avatar,
    required this.displayName,
    required this.username,
    required this.tier,
    required this.totalXpLabel,
    this.bio,
    this.isVerified = false,
    this.footer,
  });

  final Widget cover;
  final Widget avatar;
  final String displayName;
  final String username;
  final String? bio;
  final bool isVerified;
  final String tier;
  final String totalXpLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            cover,
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: -49,
              child: Center(child: avatar),
            ),
          ],
        ),
        const SizedBox(height: 61),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              Icon(
                key: const ValueKey('public-verification-badge'),
                Icons.verified_rounded,
                color: ProfilePalette.green(context),
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '@$username',
          style: TextStyle(color: ProfilePalette.muted(context)),
        ),
        if (bio?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            bio!.trim(),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProfilePalette.muted(context),
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 18),
        footer ??
            ProfilePanel(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ProfilePalette.greenSoft(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: ProfilePalette.green(context),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      readableProfileName(tier),
                      style: TextStyle(
                        color: ProfilePalette.green(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    totalXpLabel,
                    style: TextStyle(
                      color: ProfilePalette.text(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

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

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ProfilePalette.editorialSurface(context),
      borderRadius: AppRadii.fullBorder,
      border: Border.all(
        color: ProfilePalette.border(context).withValues(alpha: .55),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _ProfileTabButton(
            key: const ValueKey('profile-posts-tab'),
            label: postsLabel,
            selected: selected == ProfileTab.posts,
            onTap: () => onSelected(ProfileTab.posts),
          ),
          const SizedBox(width: 4),
          _ProfileTabButton(
            key: const ValueKey('profile-achievements-tab'),
            label: achievementsLabel,
            selected: selected == ProfileTab.achievements,
            onTap: () => onSelected(ProfileTab.achievements),
          ),
          const SizedBox(width: 4),
          _ProfileTabButton(
            key: const ValueKey('profile-rank-tab'),
            label: rankLabel,
            selected: selected == ProfileTab.rank,
            onTap: () => onSelected(ProfileTab.rank),
          ),
        ],
      ),
    ),
  );
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: AppRadii.smallBorder,
      onTap: onTap,
      child: AnimatedContainer(
        duration: RiksaMotion.resolve(context, RiksaMotion.standard),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? ProfilePalette.aubergine(context)
              : Colors.transparent,
          borderRadius: AppRadii.fullBorder,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? ProfilePalette.onAubergine(context)
                : ProfilePalette.muted(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.gamificationOrangeSoft,
                shape: BoxShape.circle,
              ),
              child: iconUrl?.trim().isNotEmpty == true
                  ? Image.network(
                      iconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.workspace_premium_rounded,
                        color: context.riksa.saffron,
                      ),
                    )
                  : Icon(
                      Icons.workspace_premium_rounded,
                      color: context.riksa.saffron,
                    ),
            ),
            const Spacer(),
            if (trailingLabel?.isNotEmpty == true)
              Flexible(
                child: Text(
                  trailingLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProfilePalette.xp(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, height: 1.2),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
    required this.icon,
    required this.label,
    required this.rank,
    required this.unrankedLabel,
    this.trailing,
  });

  final IconData icon;
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
          child: Icon(icon, color: ProfilePalette.green(context)),
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
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                rank != null && rank! > 0 ? '#$rank' : unrankedLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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
