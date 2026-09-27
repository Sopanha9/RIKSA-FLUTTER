import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_theme.dart';

const double minPostPhotoAspectRatio = 4 / 5;
const double maxPostPhotoAspectRatio = 16 / 9;

double clampPostPhotoAspectRatio(double ratio) =>
    ratio.clamp(minPostPhotoAspectRatio, maxPostPhotoAspectRatio).toDouble();

String postPhotoHeroTag(String url, {String? postId, int index = 0}) =>
    'community-photo-${postId ?? 'post'}-$index-$url';

/// A community post image with a stable portrait-first placeholder and a
/// measured aspect ratio once the image stream resolves.
class PostPhoto extends StatefulWidget {
  const PostPhoto({
    super.key,
    required this.url,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double? aspectRatio;
  final BoxFit fit;
  final String? heroTag;

  @override
  State<PostPhoto> createState() => _PostPhotoState();
}

class _PostPhotoState extends State<PostPhoto> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _resolvedAspectRatio;
  double? _lastDevicePixelRatio;
  int? _requestedCacheWidth;
  int _resolutionGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (_lastDevicePixelRatio != dpr) {
      _lastDevicePixelRatio = dpr;
      _requestedCacheWidth = null;
    }
  }

  @override
  void didUpdateWidget(covariant PostPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.aspectRatio != widget.aspectRatio) {
      _detachImageListener();
      _resolvedAspectRatio = null;
      _requestedCacheWidth = null;
    }
  }

  void _resolveAspectRatio(double dpr, int cacheWidth) {
    _detachImageListener();
    if (widget.aspectRatio != null || _resolvedAspectRatio != null) return;
    final provider = ResizeImage(NetworkImage(widget.url), width: cacheWidth);
    final stream = provider.resolve(ImageConfiguration(devicePixelRatio: dpr));
    final generation = _resolutionGeneration;
    final listener = ImageStreamListener((image, synchronousCall) {
      final imageInfo = image.image;
      final ratio = imageInfo.height == 0
          ? 0.0
          : imageInfo.width / imageInfo.height;
      image.dispose();
      if (!mounted || !ratio.isFinite || ratio <= 0) return;
      void updateRatio() {
        if (!mounted ||
            generation != _resolutionGeneration ||
            _resolvedAspectRatio != null) {
          return;
        }
        setState(() => _resolvedAspectRatio = ratio);
        _detachImageListener();
      }

      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => updateRatio());
      } else {
        updateRatio();
      }
    }, onError: (exception, stackTrace) => _detachImageListener());
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _detachImageListener() {
    _resolutionGeneration++;
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detachImageListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final ratio = clampPostPhotoAspectRatio(
      widget.aspectRatio ?? _resolvedAspectRatio ?? minPostPhotoAspectRatio,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final width = math.max(1.0, availableWidth);
        final height = width / ratio;
        final cacheWidth = math.max(1, (width * dpr).ceil());
        if (widget.aspectRatio == null &&
            _requestedCacheWidth != cacheWidth &&
            _resolvedAspectRatio == null) {
          _requestedCacheWidth = cacheWidth;
          _resolveAspectRatio(dpr, cacheWidth);
        }
        final image = Image.network(
          widget.url,
          fit: widget.fit,
          cacheWidth: cacheWidth,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null || wasSynchronouslyLoaded) return child;
            return ColoredBox(
              color: palette.surfaceRaised,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: palette.inkMuted.withValues(alpha: .65),
                  size: 30,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: palette.surfaceRaised,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: palette.inkMuted,
              size: 32,
            ),
          ),
        );
        final photo = AnimatedContainer(
          key: ValueKey('post-photo-${widget.url}'),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: height,
          constraints: BoxConstraints(maxHeight: constraints.maxHeight),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: AppRadii.mediumBorder,
            border: Border.all(color: palette.outline),
          ),
          child: image,
        );
        final heroTag = widget.heroTag;
        if (heroTag == null || reducedMotion) return photo;
        return Hero(tag: heroTag, child: photo);
      },
    );
  }
}
