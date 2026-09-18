import 'package:flutter/material.dart';
import 'package:riksa_app/core/theme/app_theme.dart';

/// Academic goal or focus chosen during onboarding.
enum OnboardingGoal {
  bacII(
    id: 'BAC_II',
    icon: Icons.school_rounded,
    titleEn: 'BacII National Exam Prep',
    titleKm: 'ត្រៀមប្រឡងបាក់ឌុប (ថ្នាក់ទី១២)',
    subtitleEn: 'Target Grade A with curated exam formulas and practice',
    subtitleKm: 'ផ្តោតលើការប្រឡងយកនិទ្ទេស A ជាមួយលំហាត់គំរូ',
  ),
  stemClass(
    id: 'STEM_FOUNDATION',
    icon: Icons.auto_graph_rounded,
    titleEn: 'High School STEM Mastery',
    titleKm: 'ពង្រឹងមុខវិជ្ជាវិទ្យាសាស្ត្រ (ថ្នាក់ទី៩-១១)',
    subtitleEn: 'Build rock-solid foundations in Math, Physics, and Science',
    subtitleKm: 'ពង្រឹងមូលដ្ឋានគ្រឹះ គណិត រូប គីមី និងជីវវិទ្យា',
  ),
  curiosity(
    id: 'CURIOSITY',
    icon: Icons.psychology_rounded,
    titleEn: 'General Curiosity & Logic',
    titleKm: 'ពង្រឹងចំណេះដឹងទូទៅ និងការគិត',
    subtitleEn: 'Train your brain with bite-sized daily science puzzles',
    subtitleKm: 'ហ្វឹកហាត់ខួរក្បាលជារៀងរាល់ថ្ងៃជាមួយល្បងប្រាជ្ញា',
  );

  const OnboardingGoal({
    required this.id,
    required this.icon,
    required this.titleEn,
    required this.titleKm,
    required this.subtitleEn,
    required this.subtitleKm,
  });

  final String id;
  final IconData icon;
  final String titleEn;
  final String titleKm;
  final String subtitleEn;
  final String subtitleKm;

  String title(String languageCode) => languageCode == 'km' ? titleKm : titleEn;
  String subtitle(String languageCode) =>
      languageCode == 'km' ? subtitleKm : subtitleEn;
}

/// Starting subject selected by the learner.
enum OnboardingSubject {
  math(
    id: 'MATHEMATICS',
    icon: Icons.calculate_rounded,
    titleEn: 'Mathematics',
    titleKm: 'គណិតវិទ្យា',
    subtitleEn: 'Functions, Algebra, Geometry & Calculus',
    subtitleKm: 'អនុគមន៍ ពីជគណិត ធរណីមាត្រ និងកាល់គុល',
  ),
  physics(
    id: 'PHYSICS',
    icon: Icons.bolt_rounded,
    titleEn: 'Physics',
    titleKm: 'រូបវិទ្យា',
    subtitleEn: 'Forces, Energy, Waves & Motion',
    subtitleKm: 'កម្លាំង ថាមពល រលក និងចលនា',
  ),
  chemistry(
    id: 'CHEMISTRY',
    icon: Icons.science_rounded,
    titleEn: 'Chemistry',
    titleKm: 'គីមីវិទ្យា',
    subtitleEn: 'Reactions, Periodic Table & Organic Chemistry',
    subtitleKm: 'ប្រតិកម្មគីមី តារាងខួប និងគីមីសរីរាង្គ',
  ),
  biology(
    id: 'BIOLOGY',
    icon: Icons.biotech_rounded,
    titleEn: 'Biology',
    titleKm: 'ជីវវិទ្យា',
    subtitleEn: 'Cell Biology, Genetics & Human Systems',
    subtitleKm: 'កោសិកា ហ្សែន និងប្រព័ន្ធសារពាង្គកាយ',
  );

  const OnboardingSubject({
    required this.id,
    required this.icon,
    required this.titleEn,
    required this.titleKm,
    required this.subtitleEn,
    required this.subtitleKm,
  });

  final String id;
  final IconData icon;
  final String titleEn;
  final String titleKm;
  final String subtitleEn;
  final String subtitleKm;

  String title(String languageCode) => languageCode == 'km' ? titleKm : titleEn;
  String subtitle(String languageCode) =>
      languageCode == 'km' ? subtitleKm : subtitleEn;

  Color accentColor(BuildContext context) {
    final palette = context.riksa;
    return switch (this) {
      OnboardingSubject.math => palette.math,
      OnboardingSubject.physics => palette.science,
      OnboardingSubject.chemistry => const Color(0xFF237A5B),
      OnboardingSubject.biology => const Color(0xFFD2674A),
    };
  }

  Color softColor(BuildContext context) {
    return switch (this) {
      OnboardingSubject.math => AppColors.tileLavender,
      OnboardingSubject.physics => AppColors.tileMint,
      OnboardingSubject.chemistry => AppColors.tileGreen,
      OnboardingSubject.biology => AppColors.tilePeach,
    };
  }
}

/// Daily commitment pace chosen by the learner.
enum OnboardingPace {
  casual(
    minutes: 5,
    xpReward: 10,
    titleEn: 'Casual',
    titleKm: 'ធម្មតា',
    subtitleEn: '5 minutes / day — Great for a steady habit',
    subtitleKm: '៥ នាទី / ថ្ងៃ — ល្អសម្រាប់ការចាប់ផ្តើម',
    isRecommended: false,
  ),
  regular(
    minutes: 10,
    xpReward: 20,
    titleEn: 'Regular',
    titleKm: 'មធ្យម',
    subtitleEn: '10 minutes / day — Recommended for solid exam progress',
    subtitleKm: '១០ នាទី / ថ្ងៃ — ស័ក្តិសមបំផុតសម្រាប់ត្រៀមប្រឡង',
    isRecommended: true,
  ),
  serious(
    minutes: 15,
    xpReward: 30,
    titleEn: 'Serious',
    titleKm: 'សកម្មខ្លាំង',
    subtitleEn: '15 minutes / day — Fast-track your mastery & province rank',
    subtitleKm: '១៥ នាទី / ថ្ងៃ — ពង្រឹងសមត្ថភាពលឿន និងដណ្តើមចំណាត់ថ្នាក់',
    isRecommended: false,
  );

  const OnboardingPace({
    required this.minutes,
    required this.xpReward,
    required this.titleEn,
    required this.titleKm,
    required this.subtitleEn,
    required this.subtitleKm,
    required this.isRecommended,
  });

  final int minutes;
  final int xpReward;
  final String titleEn;
  final String titleKm;
  final String subtitleEn;
  final String subtitleKm;
  final bool isRecommended;

  String title(String languageCode) => languageCode == 'km' ? titleKm : titleEn;
  String subtitle(String languageCode) =>
      languageCode == 'km' ? subtitleKm : subtitleEn;
}

/// Interactive challenge question model used in Phase 2.
class OnboardingQuizQuestion {
  const OnboardingQuizQuestion({
    required this.id,
    required this.subject,
    required this.questionEn,
    required this.questionKm,
    required this.optionsEn,
    required this.optionsKm,
    required this.correctIndex,
    required this.kruAiSuccessEn,
    required this.kruAiSuccessKm,
    required this.kruAiHintEn,
    required this.kruAiHintKm,
  });

  final String id;
  final OnboardingSubject subject;
  final String questionEn;
  final String questionKm;
  final List<String> optionsEn;
  final List<String> optionsKm;
  final int correctIndex;
  final String kruAiSuccessEn;
  final String kruAiSuccessKm;
  final String kruAiHintEn;
  final String kruAiHintKm;

  String question(String lang) => lang == 'km' ? questionKm : questionEn;
  List<String> options(String lang) => lang == 'km' ? optionsKm : optionsEn;
  String kruAiSuccess(String lang) => lang == 'km' ? kruAiSuccessKm : kruAiSuccessEn;
  String kruAiHint(String lang) => lang == 'km' ? kruAiHintKm : kruAiHintEn;
}

/// Curated questions for each starting subject.
class OnboardingCuratedQuestions {
  OnboardingCuratedQuestions._();

  static const Map<OnboardingSubject, List<OnboardingQuizQuestion>> questions = {
    OnboardingSubject.math: [
      OnboardingQuizQuestion(
        id: 'math_q1',
        subject: OnboardingSubject.math,
        questionEn: 'What is the slope of the line given by y = 3x + 5?',
        questionKm: 'តើមេគុណប្រាប់ទិសនៃបន្ទាត់ y = 3x + 5 ស្មើនឹងប៉ុន្មាន?',
        optionsEn: ['3', '5', '3/5', '-3'],
        optionsKm: ['3', '5', '3/5', '-3'],
        correctIndex: 0,
        kruAiSuccessEn: 'Spot on! In y = mx + b, "m" is always the slope. You spotted that in seconds! 🚀',
        kruAiSuccessKm: 'ពូកែណាស់! ក្នុងសមីការ y = mx + b តម្លៃ "m" គឺជាមេគុណប្រាប់ទិស។ ចាប់ចំណុចបានលឿនមែន! 🚀',
        kruAiHintEn: 'Remember the linear equation form: y = mx + b, where m is the slope.',
        kruAiHintKm: 'ចងចាំទម្រង់សមីការបន្ទាត់ y = mx + b ដែល m គឺជាមេគុណប្រាប់ទិស។',
      ),
      OnboardingQuizQuestion(
        id: 'math_q2',
        subject: OnboardingSubject.math,
        questionEn: 'If 2x - 4 = 10, what is the value of x?',
        questionKm: 'បើ 2x - 4 = 10 តើតម្លៃនៃ x ស្មើនឹងប៉ុន្មាន?',
        optionsEn: ['7', '3', '5', '14'],
        optionsKm: ['7', '3', '5', '14'],
        correctIndex: 0,
        kruAiSuccessEn: 'Brilliant algebra! Add 4 to get 14, then divide by 2 to get 7. Grade A mastery! 🔥',
        kruAiSuccessKm: 'គណនាលឿនណាស់! បូក 4 ស្មើ 14 រួចចែកនឹង 2 ឃើញ 7។ កម្រិតនិទ្ទេស A ហ្មង! 🔥',
        kruAiHintEn: 'First add 4 to both sides (2x = 14), then divide both sides by 2.',
        kruAiHintKm: 'ដំបូងបូក 4 ទៅទាំងសងខាង (2x = 14) រួចចែកនឹង 2។',
      ),
    ],
    OnboardingSubject.physics: [
      OnboardingQuizQuestion(
        id: 'physics_q1',
        subject: OnboardingSubject.physics,
        questionEn: 'According to Newton\'s Second Law, what is the formula for Force (F)?',
        questionKm: 'យោងតាមច្បាប់ទី២ញូតុន តើកម្លាំង (F) ស្មើនឹងរូបមន្តណា?',
        optionsEn: ['F = m × a', 'F = m / a', 'F = v × t', 'F = m × g × h'],
        optionsKm: ['F = m × a', 'F = m / a', 'F = v × t', 'F = m × g × h'],
        correctIndex: 0,
        kruAiSuccessEn: 'Spot on! Force equals mass times acceleration (F = ma). A core BacII physics formula!',
        kruAiSuccessKm: 'ត្រឹមត្រូវ ១០០%! កម្លាំង = ម៉ាស × សំទុះ (F = ma)។ រូបមន្តស្នូលនៃការប្រឡងបាក់ឌុប!',
        kruAiHintEn: 'Force depends on both mass (m) and acceleration (a) multiplied together.',
        kruAiHintKm: 'កម្លាំងអាស្រ័យលើផលគុណរវាងម៉ាស (m) និងសំទុះ (a)។',
      ),
      OnboardingQuizQuestion(
        id: 'physics_q2',
        subject: OnboardingSubject.physics,
        questionEn: 'What is the standard SI unit of Energy and Work?',
        questionKm: 'តើខ្នាតអន្តរជាតិ (SI) នៃថាមពល និងកម្មន្តគឺជាអ្វី?',
        optionsEn: ['Joule (J)', 'Newton (N)', 'Watt (W)', 'Pascal (Pa)'],
        optionsKm: ['ស៊ូល (J)', 'ញូតុន (N)', 'វ៉ាត់ (W)', 'ប៉ាស្កាល់ (Pa)'],
        correctIndex: 0,
        kruAiSuccessEn: 'Excellent! Joules (J) measure both energy and work done in physical systems.',
        kruAiSuccessKm: 'ពិតជាត្រឹមត្រូវ! ស៊ូល (J) គឺជាខ្នាតអន្តរជាតិនៃថាមពល និងកម្មន្ត។',
        kruAiHintEn: 'Newton is for force, Watt is for power. Energy uses Joules.',
        kruAiHintKm: 'ញូតុនជាខ្នាតកម្លាំង វ៉ាត់ជាខ្នាតអានុភាព រីឯថាមពលប្រើស៊ូល។',
      ),
    ],
    OnboardingSubject.chemistry: [
      OnboardingQuizQuestion(
        id: 'chem_q1',
        subject: OnboardingSubject.chemistry,
        questionEn: 'What is the chemical formula for water?',
        questionKm: 'តើរូបមន្តគីមីនៃទឹកគឺជាអ្វី?',
        optionsEn: ['H₂O', 'CO₂', 'NaCl', 'H₂SO₄'],
        optionsKm: ['H₂O', 'CO₂', 'NaCl', 'H₂SO₄'],
        correctIndex: 0,
        kruAiSuccessEn: 'Classic! Two hydrogen atoms bonded covalently with one oxygen atom.',
        kruAiSuccessKm: 'ពិតជាត្រឹមត្រូវ! អាតូមអ៊ីដ្រូសែន ២ ភ្ជាប់ជាមួយអាតូមអុកស៊ីសែន ១។',
        kruAiHintEn: 'Water consists of Hydrogen (H) and Oxygen (O).',
        kruAiHintKm: 'ទឹកផ្សំឡើងពីអ៊ីដ្រូសែន (H) និងអុកស៊ីសែន (O)។',
      ),
      OnboardingQuizQuestion(
        id: 'chem_q2',
        subject: OnboardingSubject.chemistry,
        questionEn: 'What is the pH value of pure, neutral water at 25°C?',
        questionKm: 'តើតម្លៃ pH នៃទឹកបរិសុទ្ធ (សូលុយស្យុងណឺត) ស្មើនឹងប៉ុន្មាន?',
        optionsEn: ['7', '0', '14', '1'],
        optionsKm: ['7', '0', '14', '1'],
        correctIndex: 0,
        kruAiSuccessEn: 'Spot on! pH 7 is neutral; below 7 is acidic and above 7 is basic.',
        kruAiSuccessKm: 'ពូកែមែន! pH 7 ជាសូលុយស្យុងណឺត ក្រោម 7 ជាអាស៊ីត ហើយលើស 7 ជាបាស។',
        kruAiHintEn: 'On a pH scale of 0 to 14, neutral sits right in the middle.',
        kruAiHintKm: 'នៅលើមាត្រដ្ឋាន pH ពី 0 ដល់ 14 តម្លៃកណ្តាលគឺជាណឺត។',
      ),
    ],
    OnboardingSubject.biology: [
      OnboardingQuizQuestion(
        id: 'bio_q1',
        subject: OnboardingSubject.biology,
        questionEn: 'Which organelle is known as the "powerhouse" of the cell?',
        questionKm: 'តើអង្គប្រាណណាដែលផលិតថាមពល (ATP) សំខាន់សម្រាប់កោសិកា?',
        optionsEn: ['Mitochondria', 'Nucleus', 'Ribosome', 'Vacuole'],
        optionsKm: ['មីតូកុងឌ្រី', 'ណ្វៃយ៉ូ', 'រីបូសូម', 'វ៉ាគុយអូល'],
        correctIndex: 0,
        kruAiSuccessEn: 'Yes! Mitochondria generate cellular ATP energy to fuel biological processes! 🧬',
        kruAiSuccessKm: 'ពិតជាពូកែ! មីតូកុងឌ្រីជាអ្នកផលិតថាមពល ATP សម្រាប់ដំណើរការកោសិកា! 🧬',
        kruAiHintEn: 'Think of the organelle responsible for cellular respiration and ATP synthesis.',
        kruAiHintKm: 'គិតដល់អង្គប្រាណដែលទទួលបន្ទុកដង្ហើមកោសិកា និងផលិត ATP។',
      ),
      OnboardingQuizQuestion(
        id: 'bio_q2',
        subject: OnboardingSubject.biology,
        questionEn: 'What green pigment in plant chloroplasts absorbs light for photosynthesis?',
        questionKm: 'តើសារធាតុពណ៌បៃតងក្នុងក្លរ៉ូប្លាសដែលស្រូបពន្លឺសម្រាប់រស្មីសំយោគគឺជាអ្វី?',
        optionsEn: ['Chlorophyll', 'Hemoglobin', 'Melanin', 'Carotene'],
        optionsKm: ['ក្លរ៉ូភីល', 'អេម៉ូក្លូប៊ីន', 'មេឡានីន', 'ការ៉ូតែន'],
        correctIndex: 0,
        kruAiSuccessEn: 'Awesome! Chlorophyll captures sunlight to convert water and CO₂ into glucose.',
        kruAiSuccessKm: 'ត្រឹមត្រូវណាស់! ក្លរ៉ូភីលស្រូបពន្លឺព្រះអាទិត្យសម្រាប់ដំណើរការរស្មីសំយោគ។',
        kruAiHintEn: 'It gives leaves their vibrant green color.',
        kruAiHintKm: 'ជាសារធាតុដែលធ្វើឱ្យស្លឹកឈើមានពណ៌បៃតងស្រស់។',
      ),
    ],
  };

  static List<OnboardingQuizQuestion> forSubject(OnboardingSubject subject) {
    return questions[subject] ?? questions[OnboardingSubject.math]!;
  }
}

/// Immutable data state capturing the learner's initial choices.
@immutable
class OnboardingSetupData {
  const OnboardingSetupData({
    this.goal,
    this.subject,
    this.provinceId,
    this.provinceNameLatin,
    this.provinceNameKhmer,
    this.pace,
    this.quizAnswer1Index,
    this.quizAnswer2Index,
    this.earnedXp = 0,
  });

  final OnboardingGoal? goal;
  final OnboardingSubject? subject;
  final String? provinceId;
  final String? provinceNameLatin;
  final String? provinceNameKhmer;
  final OnboardingPace? pace;
  final int? quizAnswer1Index;
  final int? quizAnswer2Index;
  final int earnedXp;

  OnboardingSetupData copyWith({
    OnboardingGoal? goal,
    OnboardingSubject? subject,
    String? provinceId,
    String? provinceNameLatin,
    String? provinceNameKhmer,
    OnboardingPace? pace,
    int? quizAnswer1Index,
    int? quizAnswer2Index,
    int? earnedXp,
  }) {
    return OnboardingSetupData(
      goal: goal ?? this.goal,
      subject: subject ?? this.subject,
      provinceId: provinceId ?? this.provinceId,
      provinceNameLatin: provinceNameLatin ?? this.provinceNameLatin,
      provinceNameKhmer: provinceNameKhmer ?? this.provinceNameKhmer,
      pace: pace ?? this.pace,
      quizAnswer1Index: quizAnswer1Index ?? this.quizAnswer1Index,
      quizAnswer2Index: quizAnswer2Index ?? this.quizAnswer2Index,
      earnedXp: earnedXp ?? this.earnedXp,
    );
  }
}
