import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../network/api_config.dart';

const humationAvatarCount = 24;
const _humationAssetDirectory = 'assets/images/avatars/humation';

String humationAvatarValue(int index) {
  if (index < 0 || index >= humationAvatarCount) {
    throw RangeError.range(index, 0, humationAvatarCount - 1, 'index');
  }
  final number = (index + 1).toString().padLeft(2, '0');
  return '/avatars/humation/avatar-$number.svg';
}

String? humationAvatarAssetPath(String? value) {
  final path = value?.trim();
  if (path == null) return null;
  final match = RegExp(
    r'^/avatars/humation/avatar-(\d{2})\.svg$',
  ).firstMatch(path);
  if (match == null) return null;
  final number = int.tryParse(match.group(1)!);
  if (number == null || number < 1 || number > humationAvatarCount) {
    return null;
  }
  return '$_humationAssetDirectory/avatar-${match.group(1)}.svg';
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
