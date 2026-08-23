import 'package:flutter/material.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_models.dart';

class ProfilePalette {
  ProfilePalette._();

  static const green = AppColors.brandPrimaryHover;
  static const streak = Color(0xFFFF8A3D);
  static const xp = Color(0xFFE8A900);

  static Color canvas(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

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

String? profileAssetUrl(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return null;
  final uri = Uri.tryParse(path);
  if (uri?.hasScheme == true) return path;
  return '${ApiConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}';
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
    final url = profileAssetUrl(avatarPath ?? user.avatarUrl);
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ProfilePalette.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: ProfilePalette.green.withValues(alpha: .18),
            blurRadius: 22,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius - 4,
        backgroundColor: ProfilePalette.panelSoft(context),
        foregroundImage: url == null ? null : NetworkImage(url),
        onForegroundImageError: url == null ? null : (_, _) {},
        child: Text(
          name.isEmpty ? 'R' : name.characters.first.toUpperCase(),
          style: TextStyle(
            color: ProfilePalette.text(context),
            fontSize: radius * .55,
            fontWeight: FontWeight.w900,
          ),
        ),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: ProfilePalette.border(context)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding ?? const EdgeInsets.all(18), child: child),
  );
}
