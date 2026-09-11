import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/userProfile/data/profile_media_storage.dart';
import '../network/api_config.dart';

const humationAvatarCount = 24;
const _humationAssetDirectory = 'assets/images/avatars/humation';
const _avatarFrameAssetDirectory = 'assets/images/avatar_frames';
const _avatarFrameTiers = <String>{
  'BRONZE',
  'SILVER',
  'GOLD',
  'PLATINUM',
  'DIAMOND',
  'LEGEND',
};

/// Resolves only rank tiers for which this build contains frame artwork.
///
/// XP thresholds remain server-owned. The client decorates the tier it was
/// given and never tries to derive a tier from total XP.
String? riksaAvatarFrameAssetPath(String? tier) {
  final normalized = tier?.trim().toUpperCase();
  if (normalized == null || !_avatarFrameTiers.contains(normalized)) {
    return null;
  }
  return '$_avatarFrameAssetDirectory/${normalized.toLowerCase()}.png';
}

String humationAvatarValue(int index) {
  if (index < 0 || index >= humationAvatarCount) {
    throw RangeError.range(index, 0, humationAvatarCount - 1, 'index');
  }
  return '/avatars/avatar-${index + 1}.png';
}

String? humationAvatarAssetPath(String? value) {
  final path = value?.trim();
  if (path == null) return null;
  // Persist the API's accepted catalog value while rendering the matching
  // bundled Humation artwork. The SVG form remains readable for users who
  // selected an avatar in an earlier app build.
  final match =
      RegExp(r'^/avatars/avatar-(\d{1,2})\.png$').firstMatch(path) ??
      RegExp(r'^/avatars/humation/avatar-(\d{2})\.svg$').firstMatch(path);
  if (match == null) return null;
  final number = int.tryParse(match.group(1)!);
  if (number == null || number < 1 || number > humationAvatarCount) {
    return null;
  }
  final assetNumber = number.toString().padLeft(2, '0');
  return '$_humationAssetDirectory/avatar-$assetNumber.svg';
}

String? resolvedAvatarUrl(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty || humationAvatarAssetPath(path) != null) {
    return null;
  }
  final uri = Uri.tryParse(path);
  if (uri?.hasScheme == true) return path;
  return '${ApiConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}';
}

class RiksaAvatarImage extends StatelessWidget {
  const RiksaAvatarImage({
    super.key,
    required this.value,
    required this.label,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
    this.frameTier,
  });

  final String? value;
  final String label;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? frameTier;

  @override
  Widget build(BuildContext context) {
    final localPath = localProfileMediaPath(value);
    final assetPath = humationAvatarAssetPath(value);
    final networkUrl = resolvedAvatarUrl(value);
    final frameAssetPath = riksaAvatarFrameAssetPath(frameTier);

    Widget avatar(double diameter) {
      final fallback = _AvatarFallback(
        label: label,
        foregroundColor: foregroundColor,
        fontSize: diameter * .42,
      );

      return SizedBox.square(
        dimension: diameter,
        child: ClipOval(
          child: ColoredBox(
            color: backgroundColor,
            child: localPath != null
                ? Image.file(
                    File(localPath),
                    key: const ValueKey('local-profile-avatar'),
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : assetPath != null
                ? SvgPicture.asset(
                    assetPath,
                    key: ValueKey(
                      'humation-avatar-${assetPath.split('/').last}',
                    ),
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  )
                : networkUrl != null
                ? Image.network(
                    networkUrl,
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
        ),
      );
    }

    if (frameAssetPath == null) return avatar(size);
    final frameName = frameAssetPath.split('/').last.split('.').first;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatar(size * .66),
          Positioned.fill(
            child: Image.asset(
              frameAssetPath,
              key: ValueKey('avatar-frame-$frameName'),
              fit: BoxFit.contain,
              cacheWidth: 384,
              cacheHeight: 384,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.label,
    required this.foregroundColor,
    required this.fontSize,
  });

  final String label;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    return Center(
      child: Text(
        trimmed.isEmpty ? 'R' : trimmed.characters.first.toUpperCase(),
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
