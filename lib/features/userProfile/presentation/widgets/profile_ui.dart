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
  });

  final AuthUser user;
  final double radius;
  final String? avatarPath;

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
        color: context.riksa.jadeSoft,
        border: Border.all(color: context.riksa.jade, width: 2),
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
