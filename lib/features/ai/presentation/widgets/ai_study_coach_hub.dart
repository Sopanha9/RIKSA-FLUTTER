import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StudyCoachTopic {
  const StudyCoachTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.context,
    required this.icon,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final String prompt;
  final String context;
  final IconData icon;
  final Color accentColor;
}

const studyCoachTopics = <StudyCoachTopic>[
  StudyCoachTopic(
    id: 'math',
    title: 'Mathematics Coach',
    subtitle: 'Step-by-step algebra, calculus & geometry problem solver',
    prompt: 'Can you help me solve a math problem step-by-step?',
    context:
        'Subject: Mathematics. You are a patient, expert math coach for Cambodian students. Guide the student step-by-step through solving equations, calculus, or geometry problems. Explain formulas clearly, teach reasoning, and ask checking questions.',
    icon: Icons.calculate_rounded,
    accentColor: Color(0xFF2563EB), // Blue
  ),
  StudyCoachTopic(
    id: 'science',
    title: 'Science Explainer',
    subtitle: 'Physics laws, chemistry formulas & biology made simple',
    prompt: 'Can you explain a scientific concept to me with an everyday example?',
    context:
        'Subject: General Science (Physics, Chemistry, Biology). Break down complex natural laws, chemical reactions, and biology systems using intuitive everyday analogies and clear step-by-step reasoning in Khmer/English.',
    icon: Icons.science_rounded,
    accentColor: Color(0xFF059669), // Emerald
  ),
  StudyCoachTopic(
    id: 'khmer',
    title: 'Khmer Language Coach',
    subtitle: 'Spelling, grammar, respectful speech & classical essays',
    prompt: 'ខ្ញុំចង់រៀនអំពីក្បួនវេយ្យាករណ៍ និងការប្រើប្រាស់ពាក្យខ្មែរឲ្យបានត្រឹមត្រូវ។',
    context:
        'Subject: Khmer Language and Literature (ភាសាខ្មែរ និងអក្សរសាស្ត្រ). You are a patient Khmer language teacher. Help students understand grammar rules, consonants, vowels, subscript rules (ជើងអក្សរ), respectful vocabulary (ពាក្យគួរសម/សំពះ), and classical essay writing.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFFD97706), // Amber
  ),
  StudyCoachTopic(
    id: 'english',
    title: 'English Practice',
    subtitle: 'Conversation partner with gentle grammar corrections',
    prompt: 'Hi! Can we practice conversational English today? Please correct any mistakes I make.',
    context:
        'Subject: English Language Learning. You are an encouraging conversational English coach. Talk with the student in clear English. Whenever they make a grammar or spelling mistake, gently point it out, explain the correct way, and continue the conversation.',
    icon: Icons.translate_rounded,
    accentColor: Color(0xFF7C3AED), // Purple
  ),
  StudyCoachTopic(
    id: 'bakii',
    title: 'Grade 12 BakII Prep',
    subtitle: 'Typical national exam questions & revision strategies',
    prompt: 'Can you quiz me on typical Grade 12 national exam questions and check my answers?',
    context:
        'Subject: Cambodian National High School Exam (បាក់ឌុប / Grade 12 BakII). Help the student prepare for national exams. Provide typical exam questions, quiz them, review their answers, and share effective revision strategies.',
    icon: Icons.school_rounded,
    accentColor: Color(0xFFDC2626), // Rose
  ),
];

class AiStudyCoachHub extends StatelessWidget {
  const AiStudyCoachHub({
    super.key,
    required this.onTopicSelected,
  });

  final void Function(StudyCoachTopic topic) onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: riksa.jade.withValues(alpha: 0.12),
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: Icon(Icons.school_outlined, size: 18, color: riksa.jade),
              ),
              const SizedBox(width: RiksaSpacing.xs),
              Text(
                'STUDY SUBJECT COACHES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: riksa.inkFaint,
                      fontWeight: FontWeight.bold,
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
  const _StudyCoachCard({
    required this.topic,
    required this.onTap,
  });

  final StudyCoachTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riksa = context.riksa;
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
              border: Border.all(
                color: riksa.inkFaint.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: topic.accentColor.withValues(alpha: 0.12),
                        borderRadius: AppRadii.mediumBorder,
                      ),
                      child: Icon(
                        topic.icon,
                        color: topic.accentColor,
                        size: 20,
                      ),
                    ),
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
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.subtitle,
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
