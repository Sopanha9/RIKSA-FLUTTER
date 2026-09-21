import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 44,
                color: context.riksa.inkMuted,
              ),
              const SizedBox(height: RiksaSpacing.sm),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: context.riksa.inkMuted),
              ),
              if (normalized.isNotEmpty) ...[
                const SizedBox(height: RiksaSpacing.md),
                FilledButton.tonalIcon(
                  key: const ValueKey('ask-ai-coach-search-button'),
                  onPressed: () {
                    final prompt = query.trim();
                    final router = GoRouter.of(context);
                    close(context, null);
                    router.push(
                      Uri(
                        path: '/ai/chat/new',
                        queryParameters: {'prompt': prompt},
                      ).toString(),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    AppLocalizations.of(context)!.aiAskCoachAbout(query.trim()),
                  ),
                ),
              ],
            ],
          ),
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
          leading: SubjectPixelArtwork(subject: subject, size: 42),
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
