import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Pushes the full-screen reader for one or more post photos.
Future<void> openPhotoViewer(
  BuildContext context, {
  required List<String> urls,
  required int initialIndex,
  required String heroTag,
}) {
  if (urls.isEmpty) return Future<void>.value();
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierColor: Colors.black,
      transitionDuration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      reverseTransitionDuration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) => PhotoViewer(
        urls: urls,
        initialIndex: initialIndex,
        heroTag: heroTag,
        useHero: !reducedMotion,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
    required this.heroTag,
    this.useHero = true,
  });

  final List<String> urls;
  final int initialIndex;
  final String heroTag;
  final bool useHero;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final TransformationController _transformController;
  late final PageController _pageController;
  late int _index;
  int? _pointerId;
  Offset? _pointerOrigin;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1).toInt();
    _transformController = TransformationController();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleZoom(Size size) {
    final currentlyZoomed =
        _transformController.value.getMaxScaleOnAxis() > 1.05;
    if (currentlyZoomed) {
      _transformController.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(
        size.width * (1 - scale) / 2,
        size.height * (1 - scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerId != null || event.kind != PointerDeviceKind.touch) return;
    _pointerId = event.pointer;
    _pointerOrigin = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDismissing || event.pointer != _pointerId) return;
    if (_transformController.value.getMaxScaleOnAxis() > 1.05) return;
    final origin = _pointerOrigin;
    if (origin == null) return;
    final delta = event.position - origin;
    if (delta.dy > 110 && delta.dy > delta.dx.abs() * 1.2) {
      _isDismissing = true;
      Navigator.of(context).maybePop();
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _pointerId) return;
    _pointerId = null;
    _pointerOrigin = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final tag = widget.heroTag;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: PageView.builder(
                  itemCount: widget.urls.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    _transformController.value = Matrix4.identity();
                    setState(() => _index = index);
                  },
                  itemBuilder: (context, index) {
                    final image = GestureDetector(
                      onDoubleTap: () => _toggleZoom(size),
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1,
                        maxScale: 5,
                        alignment: Alignment.center,
                        panEnabled: true,
                        scaleEnabled: true,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: Image.network(
                            widget.urls[index],
                            fit: BoxFit.contain,
                            cacheWidth: math.max(
                              1,
                              (size.width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                            ),
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white.withValues(alpha: .7),
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    );
                    if (index != widget.initialIndex || !widget.useHero) {
                      return image;
                    }
                    return Hero(tag: tag, child: image);
                  },
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: IconButton.filledTonal(
                key: const ValueKey('photo-viewer-close'),
                tooltip: l10n.photoViewerClose,
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
