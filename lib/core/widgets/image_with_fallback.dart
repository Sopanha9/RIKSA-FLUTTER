import 'package:flutter/material.dart';

/// A network image with a themed placeholder shown on error or while loading.
class ImageWithFallback extends StatelessWidget {
  const ImageWithFallback({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          child: Icon(fallbackIcon, color: theme.colorScheme.outline),
        );

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder();
      },
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
}
