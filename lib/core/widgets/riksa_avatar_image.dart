import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../network/api_config.dart';

const humationAvatarCount = 24;
const _humationAssetDirectory = 'assets/images/avatars/humation';

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
  });

  final String? value;
  final String label;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final assetPath = humationAvatarAssetPath(value);
    final networkUrl = resolvedAvatarUrl(value);
    final fallback = _AvatarFallback(
      label: label,
      foregroundColor: foregroundColor,
      fontSize: size * .42,
    );

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: backgroundColor,
          child: assetPath != null
              ? SvgPicture.asset(
                  assetPath,
                  key: ValueKey('humation-avatar-${assetPath.split('/').last}'),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                )
              : networkUrl != null
              ? Image.network(
                  networkUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => fallback,
                )
              : fallback,
        ),
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
