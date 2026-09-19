import 'dart:math' as math;

class LearningInsight {
  const LearningInsight({
    required this.subjectKey,
    required this.tag,
    required this.title,
    required this.body,
    required this.takeaway,
  });

  final String subjectKey; // 'khmer', 'math', 'science', 'english', 'general'
  final String tag;
  final String title;
  final String body;
  final String takeaway;
}

const allLearningInsights = <LearningInsight>[
  // Khmer & Culture
  LearningInsight(
    subjectKey: 'khmer',
    tag: 'CULTURAL ETIQUETTE',
    title: 'The 5 Levels of Sampeah',
    body:
        'In Cambodian etiquette, the height of your Sampeah expresses gratitude: chest for peers, mouth/nose for elders & teachers, eyebrows for monks, and above head for the sacred.',
    takeaway: 'Respectful body language and polite speech go hand-in-hand in Khmer.',
  ),
  LearningInsight(
    subjectKey: 'khmer',
    tag: 'KHMER LINGUISTICS',
    title: 'Consonant Subscripts (ជើងអក្សរ)',
    body:
        'Khmer script has 33 consonants, and almost all of them have a subscript form (cheung) written beneath other letters to create blended sounds.',
    takeaway: 'Mastering subscript consonants unlocks the beauty of reading Khmer poetry and books.',
  ),

  // Mathematics
  LearningInsight(
    subjectKey: 'math',
    tag: 'MATHEMATICAL HERITAGE',
    title: 'The Ancient Zero of Sambor',
    body:
        'The Khmer stone inscription found at Sambor (dated 683 AD) contains one of the oldest recorded uses of the numeral zero (០) in human history.',
    takeaway: 'Cambodia was an early pioneer of numeral systems and mathematical notation.',
  ),
  LearningInsight(
    subjectKey: 'math',
    tag: 'PROBLEM SOLVING',
    title: 'Work Backwards from the Goal',
    body:
        'When an algebra or geometry problem looks impossible, start from the answer you need and step in reverse to uncover the hidden connection.',
    takeaway: 'Great mathematicians solve proofs by reversing the path.',
  ),

  // Science
  LearningInsight(
    subjectKey: 'science',
    tag: 'NATURAL SCIENCE',
    title: 'The Reversing Tonle Sap',
    body:
        'The Tonle Sap River is one of the only rivers in the world that reverses its flow direction twice a year, expanding the lake over 5 times its dry size during monsoons.',
    takeaway: 'Hydrology and seasonal flood pulses sustain Cambodia’s rich ecosystem.',
  ),
  LearningInsight(
    subjectKey: 'science',
    tag: 'PHYSICS & COSMOLOGY',
    title: 'Stardust in You',
    body:
        'Nearly every heavy element in our bodies—carbon, nitrogen, and oxygen—was forged billions of years ago inside the nuclear fusion furnace of a dying star.',
    takeaway: 'Science reveals how intimately we are connected to the physical universe.',
  ),

  // English
  LearningInsight(
    subjectKey: 'english',
    tag: 'FLUENCY HABIT',
    title: 'Natural Conversational Cadence',
    body:
        'When native English speakers greet each other with "How\'s it going?", it is a friendly salute. The most natural response is simply "Good, you?"',
    takeaway: 'Focus on natural conversational flow rather than textbook stiffness.',
  ),
  LearningInsight(
    subjectKey: 'english',
    tag: 'MEMORY BOOST',
    title: 'Speaking Out Loud',
    body:
        'Practicing vocabulary out loud activates auditory memory and trains muscle memory in your vocal cords, increasing retention by over 40%.',
    takeaway: 'Read your English practice sentences aloud every day.',
  ),

  // General Study Habits
  LearningInsight(
    subjectKey: 'general',
    tag: 'STUDY WISDOM',
    title: 'The Power of 10-Minute Streaks',
    body:
        'Consistent daily practice of just 10 minutes creates stronger long-term memory pathways than cramming for 3 hours once a week.',
    takeaway: 'Consistency always beats intensity in learning.',
  ),
];

LearningInsight resolveInsightForCategory(String? categoryName) {
  if (categoryName == null || categoryName.trim().isEmpty) {
    return allLearningInsights[math.Random().nextInt(allLearningInsights.length)];
  }

  final lower = categoryName.toLowerCase();
  String key = 'general';
  if (lower.contains('khmer') || lower.contains('literature')) {
    key = 'khmer';
  } else if (lower.contains('math')) {
    key = 'math';
  } else if (lower.contains('physic') ||
      lower.contains('chem') ||
      lower.contains('bio') ||
      lower.contains('science')) {
    key = 'science';
  } else if (lower.contains('english')) {
    key = 'english';
  }

  final matching = allLearningInsights.where((i) => i.subjectKey == key).toList();
  if (matching.isEmpty) {
    return allLearningInsights[math.Random().nextInt(allLearningInsights.length)];
  }
  return matching[math.Random().nextInt(matching.length)];
}
