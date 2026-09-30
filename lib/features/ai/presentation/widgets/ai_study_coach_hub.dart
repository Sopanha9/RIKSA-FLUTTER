import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

class StudyCoachTopic {
  const StudyCoachTopic({
    required this.id,
    required this.prompt,
    required this.context,
    required this.icon,
    required this.accentColor,
  });

  final String id;
  final String prompt;
  final String context;
  final IconData icon;
  final Color accentColor;

  String title(AppLocalizations l10n) => switch (id) {
    'math' => l10n.aiCoachMathTitle,
    'science' => l10n.aiCoachScienceTitle,
    'khmer' => l10n.aiCoachKhmerTitle,
    'english' => l10n.aiCoachEnglishTitle,
    'bakii' => l10n.aiCoachBakiiTitle,
    _ => throw ArgumentError.value(id, 'id', 'Unknown study coach topic'),
  };

  String subtitle(AppLocalizations l10n) => switch (id) {
    'math' => l10n.aiCoachMathSubtitle,
    'science' => l10n.aiCoachScienceSubtitle,
    'khmer' => l10n.aiCoachKhmerSubtitle,
    'english' => l10n.aiCoachEnglishSubtitle,
    'bakii' => l10n.aiCoachBakiiSubtitle,
    _ => throw ArgumentError.value(id, 'id', 'Unknown study coach topic'),
  };
}

const studyCoachTopics = <StudyCoachTopic>[
  StudyCoachTopic(
    id: 'math',
    prompt: 'Can you help me solve a math problem step-by-step?',
    context:
        'Subject: Mathematics. You are a patient, expert math coach for Cambodian students. Guide the student step-by-step through solving equations, calculus, or geometry problems. Explain formulas clearly, teach reasoning, and ask checking questions.',
    icon: Icons.calculate_rounded,
    accentColor: Color(0xFF2563EB), // Blue
  ),
  StudyCoachTopic(
    id: 'science',
    prompt:
        'Can you explain a scientific concept to me with an everyday example?',
    context:
        'Subject: General Science (Physics, Chemistry, Biology). Break down complex natural laws, chemical reactions, and biology systems using intuitive everyday analogies and clear step-by-step reasoning in Khmer/English.',
    icon: Icons.science_rounded,
    accentColor: Color(0xFF059669), // Emerald
  ),
  StudyCoachTopic(
    id: 'khmer',
    prompt:
        'ខ្ញុំចង់រៀនអំពីក្បួនវេយ្យាករណ៍ និងការប្រើប្រាស់ពាក្យខ្មែរឲ្យបានត្រឹមត្រូវ។',
    context:
        'Subject: Khmer Language and Literature (ភាសាខ្មែរ និងអក្សរសាស្ត្រ). You are a patient Khmer language teacher. Help students understand grammar rules, consonants, vowels, subscript rules (ជើងអក្សរ), respectful vocabulary (ពាក្យគួរសម/សំពះ), and classical essay writing.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFFD97706), // Amber
  ),
  StudyCoachTopic(
    id: 'english',
    prompt:
        'Hi! Can we practice conversational English today? Please correct any mistakes I make.',
    context:
        'Subject: English Language Learning. You are an encouraging conversational English coach. Talk with the student in clear English. Whenever they make a grammar or spelling mistake, gently point it out, explain the correct way, and continue the conversation.',
    icon: Icons.translate_rounded,
    accentColor: Color(0xFF7C3AED), // Purple
  ),
  StudyCoachTopic(
    id: 'bakii',
    prompt:
        'Can you quiz me on typical Grade 12 national exam questions and check my answers?',
    context:
        'Subject: Cambodian National High School Exam (បាក់ឌុប / Grade 12 BakII). Help the student prepare for national exams. Provide typical exam questions, quiz them, review their answers, and share effective revision strategies.',
    icon: Icons.school_rounded,
    accentColor: Color(0xFFDC2626), // Rose
  ),
];

class AiStudyCoachHub extends StatelessWidget {
  const AiStudyCoachHub({super.key, required this.onTopicSelected});

  final void Function(StudyCoachTopic topic) onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.lg),
          child: Row(
            children: [
              const _CoachPixelIcon(topicId: 'section', size: 34),
              const SizedBox(width: RiksaSpacing.xs),
              Text(
                l10n.aiCoachSectionTitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: riksa.inkFaint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RiksaSpacing.sm),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.lg),
            itemCount: studyCoachTopics.length,
            separatorBuilder: (_, _) => const SizedBox(width: RiksaSpacing.sm),
            itemBuilder: (context, index) {
              final topic = studyCoachTopics[index];
              return _StudyCoachCard(
                topic: topic,
                onTap: () => onTopicSelected(topic),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StudyCoachCard extends StatelessWidget {
  const _StudyCoachCard({required this.topic, required this.onTap});

  final StudyCoachTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 220,
      child: Material(
        color: riksa.surface,
        borderRadius: AppRadii.largeBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.largeBorder,
          child: Container(
            padding: const EdgeInsets.all(RiksaSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadii.largeBorder,
              border: Border.all(color: riksa.inkFaint.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CoachPixelIcon(topicId: topic.id, size: 42),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: riksa.inkFaint,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.subtitle(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: riksa.inkMuted,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachPixelIcon extends StatelessWidget {
  const _CoachPixelIcon({required this.topicId, this.size = 42});

  final String topicId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _CoachPixelIconPainter(topicId)),
  );
}

class _CoachPixelIconPainter extends CustomPainter {
  const _CoachPixelIconPainter(this.topicId);

  final String topicId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final palette = _CoachIconPalette.forTopic(topicId);
    canvas.drawRRect(_rr(6, 5, 52, 52, 12), _fill(palette.bg));
    canvas.drawRect(
      const Rect.fromLTWH(12, 10, 4, 4),
      _fill(Colors.white.withValues(alpha: .78)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(17, 7, 5, 5),
      _fill(Colors.white.withValues(alpha: .62)),
    );

    switch (topicId) {
      case 'math':
        _paintMath(canvas, palette);
      case 'science':
        _paintScience(canvas, palette);
      case 'khmer':
        _paintBook(canvas, palette);
      case 'english':
        _paintTranslate(canvas, palette);
      case 'bakii':
      case 'section':
        _paintCap(canvas, palette);
      default:
        _paintSpark(canvas, palette);
    }
  }

  void _paintMath(Canvas c, _CoachIconPalette p) {
    c.drawRect(const Rect.fromLTWH(17, 16, 30, 31), _fill(p.light));
    c.drawRect(const Rect.fromLTWH(17, 16, 30, 31), _stroke(p.edge, 3));
    for (final y in const [24.0, 32.0, 40.0]) {
      c.drawLine(Offset(22, y), Offset(42, y), _stroke(p.soft, 2));
    }
    final sigma = Path()
      ..moveTo(27, 22)
      ..lineTo(43, 22)
      ..lineTo(35, 31)
      ..lineTo(43, 42)
      ..lineTo(26, 42)
      ..lineTo(35, 32)
      ..close();
    c.drawPath(sigma, _fill(p.main));
    c.drawPath(sigma, _stroke(p.edge, 2));
  }

  void _paintScience(Canvas c, _CoachIconPalette p) {
    c.drawRect(const Rect.fromLTWH(27, 15, 10, 6), _fill(p.main));
    c.drawRect(const Rect.fromLTWH(30, 21, 4, 12), _fill(p.light));
    final flask = Path()
      ..moveTo(22, 32)
      ..lineTo(42, 32)
      ..lineTo(50, 49)
      ..lineTo(14, 49)
      ..close();
    c.drawPath(flask, _fill(p.main));
    c.drawPath(flask, _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(21, 40, 24, 5), _fill(p.soft));
    c.drawOval(const Rect.fromLTWH(18, 21, 5, 5), _fill(p.soft));
    c.drawOval(const Rect.fromLTWH(43, 17, 6, 6), _fill(p.soft));
  }

  void _paintBook(Canvas c, _CoachIconPalette p) {
    final left = Path()
      ..moveTo(15, 20)
      ..lineTo(31, 20)
      ..lineTo(31, 46)
      ..lineTo(23, 42)
      ..lineTo(15, 43)
      ..close();
    final right = Path()
      ..moveTo(33, 20)
      ..lineTo(49, 20)
      ..lineTo(49, 43)
      ..lineTo(41, 42)
      ..lineTo(33, 46)
      ..close();
    c.drawPath(left, _fill(p.light));
    c.drawPath(right, _fill(p.light));
    c.drawPath(left, _stroke(p.edge, 3));
    c.drawPath(right, _stroke(p.edge, 3));
    c.drawLine(const Offset(32, 22), const Offset(32, 47), _stroke(p.edge, 2));
    for (final y in const [27.0, 33.0, 38.0]) {
      c.drawLine(Offset(19, y), Offset(28, y), _stroke(p.main, 2));
      c.drawLine(Offset(36, y), Offset(45, y), _stroke(p.main, 2));
    }
  }

  void _paintTranslate(Canvas c, _CoachIconPalette p) {
    c.drawRect(const Rect.fromLTWH(16, 18, 23, 21), _fill(p.light));
    c.drawRect(const Rect.fromLTWH(16, 18, 23, 21), _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(27, 29, 22, 20), _fill(p.soft));
    c.drawRect(const Rect.fromLTWH(27, 29, 22, 20), _stroke(p.edge, 3));
    c.drawLine(const Offset(22, 25), const Offset(33, 25), _stroke(p.main, 2));
    c.drawLine(const Offset(27, 21), const Offset(27, 34), _stroke(p.main, 2));
    c.drawLine(const Offset(22, 35), const Offset(31, 24), _stroke(p.main, 2));
    c.drawLine(const Offset(34, 43), const Offset(39, 34), _stroke(p.main, 2));
    c.drawLine(const Offset(39, 34), const Offset(45, 43), _stroke(p.main, 2));
    c.drawLine(const Offset(36, 40), const Offset(43, 40), _stroke(p.main, 2));
  }

  void _paintCap(Canvas c, _CoachIconPalette p) {
    final cap = Path()
      ..moveTo(13, 29)
      ..lineTo(32, 18)
      ..lineTo(51, 29)
      ..lineTo(32, 40)
      ..close();
    c.drawPath(cap, _fill(p.main));
    c.drawPath(cap, _stroke(p.edge, 3));
    c.drawRect(const Rect.fromLTWH(22, 38, 20, 9), _fill(p.soft));
    c.drawRect(const Rect.fromLTWH(22, 38, 20, 9), _stroke(p.edge, 2));
    c.drawLine(const Offset(48, 31), const Offset(48, 44), _stroke(p.edge, 2));
    c.drawRect(const Rect.fromLTWH(45, 44, 6, 5), _fill(p.edge));
  }

  void _paintSpark(Canvas c, _CoachIconPalette p) {
    c.drawRect(const Rect.fromLTWH(29, 16, 6, 28), _fill(p.main));
    c.drawRect(const Rect.fromLTWH(18, 27, 28, 6), _fill(p.main));
    c.drawRect(const Rect.fromLTWH(25, 22, 14, 16), _fill(p.soft));
  }

  static Paint _fill(Color color) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  bool shouldRepaint(covariant _CoachPixelIconPainter oldDelegate) =>
      oldDelegate.topicId != topicId;
}

class _CoachIconPalette {
  const _CoachIconPalette({
    required this.bg,
    required this.edge,
    required this.main,
    required this.soft,
    required this.light,
  });

  final Color bg;
  final Color edge;
  final Color main;
  final Color soft;
  final Color light;

  static _CoachIconPalette forTopic(String topicId) => switch (topicId) {
    'math' => const _CoachIconPalette(
      bg: Color(0xFFDCEBFF),
      edge: Color(0xFF1D4EA8),
      main: Color(0xFF3779E8),
      soft: Color(0xFF8FC1FF),
      light: Color(0xFFF2F7FF),
    ),
    'science' => const _CoachIconPalette(
      bg: Color(0xFFDDF7E9),
      edge: Color(0xFF08724D),
      main: Color(0xFF11A875),
      soft: Color(0xFF77DDAF),
      light: Color(0xFFF1FFF8),
    ),
    'khmer' => const _CoachIconPalette(
      bg: Color(0xFFFFE8CF),
      edge: Color(0xFF974B08),
      main: Color(0xFFFF8A12),
      soft: Color(0xFFFFBF68),
      light: Color(0xFFFFF7E8),
    ),
    'english' => const _CoachIconPalette(
      bg: Color(0xFFE8DDFE),
      edge: Color(0xFF5A26BC),
      main: Color(0xFF884EF2),
      soft: Color(0xFFC3A6FF),
      light: Color(0xFFF8F3FF),
    ),
    'bakii' => const _CoachIconPalette(
      bg: Color(0xFFFFDCE1),
      edge: Color(0xFF9F1F2D),
      main: Color(0xFFE34455),
      soft: Color(0xFFFF9BA7),
      light: Color(0xFFFFF3F5),
    ),
    _ => const _CoachIconPalette(
      bg: Color(0xFFEDE5FF),
      edge: Color(0xFF6B3DE6),
      main: Color(0xFF8257F5),
      soft: Color(0xFFC8B7FF),
      light: Color(0xFFF7F3FF),
    ),
  };
}
