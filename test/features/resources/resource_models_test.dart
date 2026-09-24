import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/resources/data/resource_models.dart';

void main() {
  test('parses resource pages, author data and save state', () {
    final page = LessonResourcePage.fromJson({
      'edges': [
        {
          'id': 'resource-1',
          'lessonId': 'lesson-1',
          'title': 'Past paper',
          'url': 'https://www.example.edu/paper.pdf',
          'kind': 'PDF',
          'author': {'id': 'author-1', 'displayName': 'Dara'},
          'saveCount': 5,
          'savedByMe': true,
          'createdAt': '2026-09-24T10:00:00Z',
        },
      ],
      'hasNextPage': true,
      'endCursor': 'next-cursor',
    });

    expect(page.edges.single.kind, LessonResourceKind.pdf);
    expect(page.edges.single.domain, 'example.edu');
    expect(page.edges.single.author.displayName, 'Dara');
    expect(page.edges.single.savedByMe, isTrue);
    expect(page.endCursor, 'next-cursor');
  });

  test('share form rules reject unsupported schemes and invalid titles', () {
    expect(ResourceShareRules.titleError('  no '), 'title');
    expect(
      ResourceShareRules.titleError('A useful chemistry resource'),
      isNull,
    );
    expect(ResourceShareRules.urlError('file:///notes.pdf'), 'url');
    expect(ResourceShareRules.urlError('javascript:alert(1)'), 'url');
    expect(ResourceShareRules.urlError('https://example.edu/notes'), isNull);
  });
}
