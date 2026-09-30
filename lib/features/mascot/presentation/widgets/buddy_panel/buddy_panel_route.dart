import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/mascot.dart';
import 'buddy_head_art.dart';

/// Opens the buddy's quest surface as a popup unless the available layout is
/// too short, wide, or magnified for the speech bubble to remain usable.
Future<void> openBuddyPanel({
  required BuildContext context,
  required Rect headRect,
  required String openSemantics,
  required String closeSemantics,
  required Widget Function(double maxHeight) contentBuilder,
  required VoidCallback onHeadTap,
}) async {
  final media = MediaQuery.of(context);
  final size = media.size;
  final safeInsets = media.viewPadding;
  final bottomClearance = math.max(104.0, safeInsets.bottom + 90).toDouble();
  final usableTop = safeInsets.top + 12;
  final usableBottom = size.height - bottomClearance;
  final availableHeight = usableBottom - usableTop;
  final tooMagnified = media.textScaler.scale(1) >= 1.6;
  final isLandscape = size.width > size.height;
  final opensDown = headRect.center.dy < size.height / 2;
  final sideSpace = opensDown
      ? usableBottom - headRect.bottom + 4
      : headRect.top - usableTop + 4;
  final fallback =
      availableHeight < 420 || sideSpace < 420 || isLandscape || tooMagnified;

  if (fallback) {
    // The sheet stacks the drag handle, this surface, and the bottom
    // clearance; availableHeight already excludes the clearance, so leave
    // room for the handle too or the sheet is pushed below the screen.
    const dragHandleHeight = 48.0;
    final sheetHeight = math
        .max(
          0.0,
          math.min(size.height * .88, availableHeight - dragHandleHeight),
        )
        .toDouble();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: bottomClearance),
        child: BuddyPanelSheetSurface(
          height: sheetHeight,
          child: contentBuilder(sheetHeight - 28),
        ),
      ),
    );
    return;
  }

  final maxPanelHeight = math.min(availableHeight * .75, sideSpace).toDouble();
  final width = math.min(size.width - 24, 380.0).toDouble();
  final leftSnapped = headRect.center.dx < size.width / 2;
  final panelLeft = leftSnapped ? 12.0 : size.width - width - 12;
  final panelTop = opensDown
      ? headRect.bottom - 4
      : headRect.top + 4 - maxPanelHeight;
  final localAnchorX = ((headRect.center.dx - panelLeft) / width * 2 - 1)
      .clamp(-1.0, 1.0)
      .toDouble();
  final localAnchorY =
      ((headRect.center.dy - panelTop) / maxPanelHeight * 2 - 1)
          .clamp(-1.0, 1.0)
          .toDouble();
  final content = contentBuilder(maxPanelHeight - 12);
  final bubble = _BuddyBubble(
    width: width,
    height: maxPanelHeight,
    tailAtTop: opensDown,
    tailX: (headRect.center.dx - panelLeft).clamp(28.0, width - 28).toDouble(),
    child: content,
  );
  final reduceMotion = media.disableAnimations;
  final routeDuration = reduceMotion
      ? const Duration(milliseconds: 130)
      : const Duration(milliseconds: 360);

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: closeSemantics,
    barrierColor: Colors.black.withValues(alpha: .52),
    transitionDuration: routeDuration,
    pageBuilder: (_, _, _) => const SizedBox.expand(),
    transitionBuilder: (routeContext, animation, _, _) {
      final scale = reduceMotion
          ? 1.0
          : .025 + .975 * Curves.easeOutBack.transform(animation.value);
      return Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: openSemantics,
        onDismiss: onHeadTap,
        child: FocusTraversalGroup(
          child: FocusScope(
            autofocus: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: panelLeft,
                  top: panelTop,
                  width: width,
                  height: maxPanelHeight,
                  child: Transform.scale(
                    alignment: Alignment(localAnchorX, localAnchorY),
                    scale: scale,
                    child: Opacity(opacity: animation.value, child: bubble),
                  ),
                ),
                Positioned(
                  left: headRect.left,
                  top: headRect.top,
                  width: headRect.width,
                  height: headRect.height,
                  child: Semantics(
                    button: true,
                    label: openSemantics,
                    child: GestureDetector(
                      key: const ValueKey('buddy-panel-head'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onHeadTap,
                      child: Center(
                        child: BuddyHeadArt(
                          face: MascotFace.happy,
                          size: math
                              .max(headRect.width, headRect.height)
                              .toDouble(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The fallback keeps the exact same content and only changes its container.
class BuddyPanelSheetSurface extends StatelessWidget {
  const BuddyPanelSheetSurface({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Material(
        key: const ValueKey('buddy-panel-sheet'),
        color: context.riksa.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    ),
  );
}

class _BuddyBubble extends StatelessWidget {
  const _BuddyBubble({
    required this.width,
    required this.height,
    required this.tailAtTop,
    required this.tailX,
    required this.child,
  });

  final double width;
  final double height;
  final bool tailAtTop;
  final double tailX;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tailHeight = 12.0;
    return Semantics(
      key: const ValueKey('buddy-panel'),
      explicitChildNodes: true,
      child: CustomPaint(
        key: ValueKey(
          tailAtTop ? 'buddy-panel-tail-top' : 'buddy-panel-tail-bottom',
        ),
        painter: _BubblePainter(
          color: context.riksa.surface,
          tailAtTop: tailAtTop,
          tailX: tailX,
          tailHeight: tailHeight,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: tailAtTop ? tailHeight : 0,
            bottom: tailAtTop ? 0 : tailHeight,
          ),
          child: Material(
            color: context.riksa.surface,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: width,
              height: height - tailHeight,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.color,
    required this.tailAtTop,
    required this.tailX,
    required this.tailHeight,
  });

  final Color color;
  final bool tailAtTop;
  final double tailX;
  final double tailHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyTop = tailAtTop ? tailHeight : 0.0;
    final bodyBottom = tailAtTop ? size.height : size.height - tailHeight;
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, bodyTop, size.width, bodyBottom),
          const Radius.circular(24),
        ),
      );
    final tail = Path()
      ..moveTo(tailX - 12, tailAtTop ? bodyTop + 5 : bodyBottom - 5)
      ..lineTo(tailX, tailAtTop ? 0 : size.height)
      ..lineTo(tailX + 12, tailAtTop ? bodyTop + 5 : bodyBottom - 5)
      ..close();
    final path = Path.combine(PathOperation.union, body, tail);
    canvas.drawShadow(path, Colors.black.withValues(alpha: .22), 16, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      color != oldDelegate.color ||
      tailAtTop != oldDelegate.tailAtTop ||
      tailX != oldDelegate.tailX;
}
