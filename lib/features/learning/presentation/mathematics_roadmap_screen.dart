import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/learning_models.dart';

class MathematicsRoadmapScreen extends StatelessWidget {
  const MathematicsRoadmapScreen({super.key, this.currentLesson});

  final LessonSummary? currentLesson;

  static const _steps = [
    _RoadmapLesson(
      number: '01',
      title: 'Foundations',
      subtitle: 'Basic concepts and numbers',
      state: _RoadmapState.completed,
    ),
    _RoadmapLesson(
      number: '02',
      title: 'Functions & Graphs',
      subtitle: 'Understand functions and their graphs',
      state: _RoadmapState.completed,
    ),
    _RoadmapLesson(
      number: '03',
      title: 'Derivatives & Tangent Lines',
      subtitle: 'Find rates of change and tangent lines',
      state: _RoadmapState.current,
    ),
    _RoadmapLesson(
      number: '04',
      title: 'Applications of Derivatives',
      subtitle: 'Real world problems and optimization',
      state: _RoadmapState.locked,
    ),
    _RoadmapLesson(
      number: '05',
      title: 'Integrals',
      subtitle: 'Introduction to integration',
      state: _RoadmapState.locked,
    ),
    _RoadmapLesson(
      number: '06',
      title: 'Integral Applications',
      subtitle: 'Area, volume and more',
      state: _RoadmapState.locked,
    ),
    _RoadmapLesson(
      number: '07',
      title: 'Differential Equations',
      subtitle: 'Coming soon',
      state: _RoadmapState.comingSoon,
    ),
    _RoadmapLesson(
      number: '08',
      title: 'Mathematics Challenge',
      subtitle: "Test what you've learned",
      state: _RoadmapState.locked,
      milestone: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        bottom: false,
        child: ListView(
          // AppShell already reserves space for the persistent bottom navbar.
          // Keep only a natural ending after the final roadmap milestone.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _RoadmapHeader(onBack: context.pop),
            const SizedBox(height: 14),
            const _MathHero(),
            const SizedBox(height: 12),
            const _WeeklyLearningStrip(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Your path',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < _steps.length; index++)
              _RoadmapStepItem(
                step: _steps[index],
                isFirst: index == 0,
                isLast: index == _steps.length - 1,
                onOpen: _steps[index].state == _RoadmapState.current &&
                        currentLesson != null
                    ? () => context.push(
                        '/learn/${currentLesson!.id}',
                        extra: currentLesson,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapHeader extends StatelessWidget {
  const _RoadmapHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'MATHEMATICS',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.25,
          fontWeight: FontWeight.w900,
          color: context.riksa.ink,
        ),
      ),
    ],
  );
}

class _MathHero extends StatelessWidget {
  const _MathHero();

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      height: 188,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECE5F5), Color(0xFFF5F0FA)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .72)),
        boxShadow: RiksaElevation.low(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 4,
              width: 170,
              height: 165,
              child: CustomPaint(painter: _MathHeroPainter(palette.math)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MATHEMATICS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: palette.math,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 190,
                    child: Text(
                      'Your Learning\nRoadmap',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        height: 1.1,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '2 of 8 lessons completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: palette.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(
                        value: 2 / 8,
                        minHeight: 7,
                        backgroundColor: Color(0xFFDCD2E8),
                        valueColor: AlwaysStoppedAnimation(Color(0xFF76528F)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyLearningStrip extends StatelessWidget {
  const _WeeklyLearningStrip();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(18),
        boxShadow: RiksaElevation.low(Theme.of(context).brightness),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          final complete = index < 2;
          final today = index == 2;
          final color = complete
              ? context.riksa.jade
              : today
                  ? context.riksa.math
                  : context.riksa.outline;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: today ? FontWeight.w800 : FontWeight.w500,
                  color: today ? context.riksa.math : context.riksa.inkMuted,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  complete
                      ? Icons.check_rounded
                      : today
                          ? Icons.circle
                          : Icons.circle_outlined,
                  size: today ? 8 : 12,
                  color: complete || today ? Colors.white : context.riksa.inkFaint,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RoadmapStepItem extends StatelessWidget {
  const _RoadmapStepItem({
    required this.step,
    required this.isFirst,
    required this.isLast,
    this.onOpen,
  });

  final _RoadmapLesson step;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final isCurrent = step.state == _RoadmapState.current;
    final isCompleted = step.state == _RoadmapState.completed;

    // Node top offset relative to top of step row
    final double nodeCenterY = isCurrent ? 24.0 : 20.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node + Continuous Line Column
          SizedBox(
            width: 40,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Continuous Vertical Path Line
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ContinuousTimelinePainter(
                      isFirst: isFirst,
                      isLast: isLast,
                      nodeCenterY: nodeCenterY,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      color: context.riksa.jade,
                      currentColor: context.riksa.math,
                      futureColor: const Color(0xFFDDD8E6),
                    ),
                  ),
                ),
                // Timeline Node
                Positioned(
                  top: nodeCenterY - (isCurrent ? 20.0 : 16.0),
                  child: _RoadmapNode(step: step),
                ),
              ],
            ),
          ),

          // Short Horizontal Connector Arm (Attachment)
          SizedBox(
            width: 12,
            child: CustomPaint(
              painter: _ConnectorArmPainter(
                nodeCenterY: nodeCenterY,
                color: isCompleted
                    ? context.riksa.jade.withValues(alpha: .5)
                    : isCurrent
                        ? context.riksa.math.withValues(alpha: .5)
                        : const Color(0xFFDDD8E6),
              ),
            ),
          ),

          // Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: isCurrent
                  ? _CurrentRoadmapCard(step: step, onTap: onOpen)
                  : _CompactRoadmapCard(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinuousTimelinePainter extends CustomPainter {
  const _ContinuousTimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.nodeCenterY,
    required this.isCompleted,
    required this.isCurrent,
    required this.color,
    required this.currentColor,
    required this.futureColor,
  });

  final bool isFirst;
  final bool isLast;
  final double nodeCenterY;
  final bool isCompleted;
  final bool isCurrent;
  final Color color;
  final Color currentColor;
  final Color futureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Top segment (from y=0 down to node center)
    if (!isFirst) {
      final topColor = (isCompleted || isCurrent) ? color : futureColor;
      final topPaint = Paint()
        ..color = topColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, nodeCenterY), topPaint);
    }

    // Bottom segment (from node center down to y=height)
    if (!isLast) {
      if (isCompleted) {
        final solidPaint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(centerX, nodeCenterY),
          Offset(centerX, size.height),
          solidPaint,
        );
      } else {
        // Dashed line for current / future
        final futurePaint = Paint()
          ..color = futureColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        final startY = nodeCenterY;
        final endY = size.height;
        for (var y = startY; y < endY; y += 7) {
          final drawY = (y + 4 > endY) ? endY : y + 4;
          canvas.drawLine(Offset(centerX, y), Offset(centerX, drawY), futurePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContinuousTimelinePainter old) =>
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.nodeCenterY != nodeCenterY ||
      old.isCompleted != isCompleted ||
      old.isCurrent != isCurrent;
}

class _ConnectorArmPainter extends CustomPainter {
  const _ConnectorArmPainter({
    required this.nodeCenterY,
    required this.color,
  });

  final double nodeCenterY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, nodeCenterY), Offset(size.width, nodeCenterY), paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorArmPainter old) =>
      old.nodeCenterY != nodeCenterY || old.color != color;
}

class _RoadmapNode extends StatelessWidget {
  const _RoadmapNode({required this.step});
  final _RoadmapLesson step;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final completed = step.state == _RoadmapState.completed;
    final current = step.state == _RoadmapState.current;

    if (current) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.math.withValues(alpha: .18),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.math,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.math.withValues(alpha: .35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            step.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    final fill = completed
        ? palette.jade
        : step.milestone
            ? const Color(0xFFFFF0D0)
            : const Color(0xFFEFEBF5);

    final textColor = completed
        ? Colors.white
        : step.milestone
            ? const Color(0xFFD48800)
            : palette.inkMuted;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: step.milestone
            ? Border.all(color: const Color(0xFFFCE3B0), width: 1.5)
            : null,
      ),
      child: Text(
        step.number,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactRoadmapCard extends StatelessWidget {
  const _CompactRoadmapCard({required this.step});
  final _RoadmapLesson step;

  @override
  Widget build(BuildContext context) {
    final completed = step.state == _RoadmapState.completed;
    final palette = context.riksa;

    final bgColor = completed
        ? const Color(0xFFF2F9F5)
        : step.milestone
            ? const Color(0xFFFFF9EE)
            : const Color(0xFFFAF8F5);

    final borderColor = completed
        ? const Color(0xFFD5EBDC)
        : step.milestone
            ? const Color(0xFFFCEACD)
            : const Color(0xFFEEEAE3);

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: completed ? palette.ink : palette.inkMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted.withValues(alpha: completed ? .84 : .68),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            completed
                ? Icons.check_circle_rounded
                : step.milestone
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
            color: completed
                ? palette.jade
                : step.milestone
                    ? const Color(0xFFE5A000)
                    : palette.inkFaint,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CurrentRoadmapCard extends StatefulWidget {
  const _CurrentRoadmapCard({required this.step, this.onTap});
  final _RoadmapLesson step;
  final VoidCallback? onTap;

  @override
  State<_CurrentRoadmapCard> createState() => _CurrentRoadmapCardState();
}

class _CurrentRoadmapCardState extends State<_CurrentRoadmapCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: RiksaMotion.resolve(context, RiksaMotion.fast),
        scale: _pressed ? .985 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 175, maxHeight: 195),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEADDF2), Color(0xFFF3EEF8)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: palette.math.withValues(alpha: .28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.math.withValues(alpha: .12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // dy/dx Background Artwork on Right
              Positioned(
                right: -8,
                top: 0,
                bottom: 0,
                width: 125,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TangentPainter(palette.math),
                  ),
                ),
              ),
              // Left Content Layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'YOU ARE HERE',
                      style: TextStyle(
                        color: palette.math,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),

                  // Middle: Title
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Text(
                      widget.step.title,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.15,
                      ),
                    ),
                  ),

                  // Bottom: Metadata Chips + Arrow CTA Button
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: const [
                            _RoadmapFact(Icons.schedule_rounded, '8 min'),
                            _RoadmapFact(Icons.edit_note_rounded, '2 exercises'),
                            _RoadmapFact(Icons.bolt_rounded, 'Easy'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: palette.ink,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: palette.canvas,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadmapFact extends StatelessWidget {
  const _RoadmapFact(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: palette.inkMuted),
          const SizedBox(width: 3),
          Text(
            label,
            softWrap: false,
            style: TextStyle(
              color: palette.ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RoadmapState { completed, current, locked, comingSoon }

class _RoadmapLesson {
  const _RoadmapLesson({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.state,
    this.milestone = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final _RoadmapState state;
  final bool milestone;
}

class _MathHeroPainter extends CustomPainter {
  const _MathHeroPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()
      ..color = color.withValues(alpha: .10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * .58, size.height * .5), 38, line);
    canvas.drawLine(
      Offset(12, size.height * .78),
      Offset(size.width - 5, size.height * .22),
      line,
    );
    canvas.drawLine(Offset(32, 12), Offset(32, size.height - 12), line);
    canvas.drawLine(
      Offset(16, size.height - 24),
      Offset(size.width - 16, size.height - 24),
      line,
    );
    canvas.drawCircle(Offset(size.width * .72, size.height * .33), 8, fill);
    final text = TextPainter(
      text: TextSpan(
        text: '√x',
        style: TextStyle(
          color: color.withValues(alpha: .38),
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(size.width * .56, size.height * .60));
  }

  @override
  bool shouldRepaint(covariant _MathHeroPainter old) => old.color != color;
}

class _TangentPainter extends CustomPainter {
  const _TangentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * .72)
      ..quadraticBezierTo(
        size.width * .38,
        size.height * .08,
        size.width,
        size.height * .48,
      );
    canvas.drawPath(path, paint);

    // Tangent line
    canvas.drawLine(
      Offset(2, size.height * .62),
      Offset(size.width - 2, size.height * .32),
      paint,
    );

    final text = TextPainter(
      text: TextSpan(
        text: 'dy/dx',
        style: TextStyle(
          color: color.withValues(alpha: .38),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(size.width * .36, 10));
  }

  @override
  bool shouldRepaint(covariant _TangentPainter old) => old.color != color;
}
