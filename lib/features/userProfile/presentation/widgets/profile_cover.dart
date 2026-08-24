import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

@immutable
class ProfileCoverStyle {
  const ProfileCoverStyle({
    required this.id,
    required this.colors,
    required this.accent,
  });

  final String id;
  final List<Color> colors;
  final Color accent;
}

const profileCoverStyles = <ProfileCoverStyle>[
  ProfileCoverStyle(
    id: 'jade',
    colors: [Color(0xFF123D31), Color(0xFF237A5B), Color(0xFF6BBF8E)],
    accent: Color(0xFFFFD88A),
  ),
  ProfileCoverStyle(
    id: 'sunrise',
    colors: [Color(0xFF8C3D2C), Color(0xFFE08A3A), Color(0xFFF5C76C)],
    accent: Color(0xFFFFF0C9),
  ),
  ProfileCoverStyle(
    id: 'lotus',
    colors: [Color(0xFF5A294A), Color(0xFFA84F75), Color(0xFFE8A6B7)],
    accent: Color(0xFFFFE3B3),
  ),
  ProfileCoverStyle(
    id: 'mekong',
    colors: [Color(0xFF163C59), Color(0xFF28789A), Color(0xFF66B6B0)],
    accent: Color(0xFFFFD275),
  ),
  ProfileCoverStyle(
    id: 'indigo',
    colors: [Color(0xFF29284E), Color(0xFF55518C), Color(0xFF9B83B8)],
    accent: Color(0xFFF2C96D),
  ),
  ProfileCoverStyle(
    id: 'night',
    colors: [Color(0xFF151921), Color(0xFF293849), Color(0xFF415E65)],
    accent: Color(0xFFE9B949),
  ),
];

ProfileCoverStyle profileCoverStyle(String id) => profileCoverStyles.firstWhere(
  (style) => style.id == id,
  orElse: () => profileCoverStyles.first,
);

class ProfileCover extends StatelessWidget {
  const ProfileCover({
    super.key,
    required this.coverId,
    this.height = 150,
    this.borderRadius = AppRadii.mediumBorder,
  });

  final String coverId;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final style = profileCoverStyle(coverId);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
        boxShadow: [
          BoxShadow(
            color: style.colors.first.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(painter: _CoverPatternPainter(style.accent)),
    );
  }
}

class _CoverPatternPainter extends CustomPainter {
  const _CoverPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = color.withValues(alpha: .09);
    final spacing = size.height * .36;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      final center = Offset(x, size.height * .48);
      canvas.drawCircle(center, spacing * .46, line);
      canvas.drawCircle(center, spacing * .25, fill);
      canvas.drawLine(
        Offset(x - spacing * .46, size.height),
        Offset(x + spacing * .46, 0),
        line,
      );
    }

    final sun = Offset(size.width * .82, size.height * .28);
    canvas.drawCircle(sun, size.height * .095, fill);
    canvas.drawCircle(sun, size.height * .14, line);
  }

  @override
  bool shouldRepaint(covariant _CoverPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
