import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RiksaGlassSurface extends StatelessWidget {
  const RiksaGlassSurface({
    super.key,
    this.borderRadius = AppRadii.fullBorder,
    this.blurSigma = 14,
    this.padding,
    required this.child,
    this.boxShadow,
  });

  final BorderRadius borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final glass = context.riksaGlass;
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow ?? RiksaElevation.overlay(brightness),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: borderRadius,
              border: Border.all(color: glass.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class RiksaGlassSelection extends StatelessWidget {
  const RiksaGlassSelection({
    super.key,
    this.borderRadius = AppRadii.fullBorder,
    this.child,
  });

  final BorderRadius borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final glass = context.riksaGlass;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass.selectedFill,
        borderRadius: borderRadius,
        border: Border.all(color: glass.selectedBorder),
        boxShadow: RiksaElevation.raised(Theme.of(context).brightness),
      ),
      child: child,
    );
  }
}
