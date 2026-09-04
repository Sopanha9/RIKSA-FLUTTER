import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/learning_models.dart';
import '../learning_design.dart';

/// Searches the lessons already loaded for the learning home.
///
/// It filters in memory rather than hitting `/lessons` because the home screen
/// has every STEM lesson in hand: each subject's roadmap is the full ordered
/// syllabus. That keeps search instant and correct offline, and it stops the
/// two surfaces disagreeing about what exists.
class LessonSearchDelegate extends SearchDelegate<LessonSummary?> {
  LessonSearchDelegate({
    required this.lessons,
    required this.hint,
    required this.emptyLabel,
  }) : super(searchFieldLabel: hint);

  final List<LessonSummary> lessons;
  final String hint;
  final String emptyLabel;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = normalized.isEmpty
        ? lessons
        : lessons
              .where(
                (lesson) =>
                    lesson.title.toLowerCase().contains(normalized) ||
                    lesson.description.toLowerCase().contains(normalized) ||
                    lesson.categoryName.toLowerCase().contains(normalized),
              )
              .toList(growable: false);

    if (results.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: context.riksa.inkMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(RiksaSpacing.md + 2),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: RiksaSpacing.xs),
      itemBuilder: (context, index) {
        final lesson = results[index];
        final subject = stemSubjectFor(lesson.categoryName);
        final tone = subjectTone(context, subject);
        return ListTile(
          key: ValueKey('search-result-${lesson.id}'),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.largeBorder,
          ),
          tileColor: context.riksa.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RiksaSpacing.md,
            vertical: RiksaSpacing.xxs,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.surface,
              borderRadius: AppRadii.badgeBorder,
            ),
            child: Icon(
              stemSubjectIcon(subject),
              size: 19,
              color: tone.accent,
            ),
          ),
          title: Text(
            lesson.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.titleStyleFor(
              lesson.title,
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              khmerHeight: 1.35,
            ),
          ),
          subtitle: Text(
            lesson.categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.riksa.inkMuted, fontSize: 12),
          ),
          trailing: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: context.riksa.inkMuted,
          ),
          onTap: () => close(context, lesson),
        );
      },
    );
  }
}
