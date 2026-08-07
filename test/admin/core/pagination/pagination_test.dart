import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/admin/core/pagination/blog_page.dart';
import 'package:riksa_app/admin/core/pagination/cursor_page.dart';
import 'package:riksa_app/admin/core/pagination/page.dart';

void main() {
  group('ApiPage (offset pagination, doc §3.1)', () {
    test('parses Spring Page<T> shape', () {
      final json = {
        'content': [
          {'id': 'u1'},
          {'id': 'u2'},
        ],
        'number': 0,
        'size': 20,
        'totalElements': 137,
        'totalPages': 7,
        'first': true,
        'last': false,
        'empty': false,
      };

      final page = ApiPage.fromJson(
        json,
        (j) => (j as Map<String, dynamic>)['id'] as String,
      );

      expect(page.content, ['u1', 'u2']);
      expect(page.number, 0);
      expect(page.size, 20);
      expect(page.totalElements, 137);
      expect(page.totalPages, 7);
      expect(page.first, isTrue);
      expect(page.last, isFalse);
      expect(page.empty, isFalse);
    });

    test('round-trips through toJson', () {
      const page = ApiPage<String>(
        content: ['a'],
        number: 1,
        size: 10,
        totalElements: 11,
        totalPages: 2,
        first: false,
        last: true,
        empty: false,
      );

      final decoded = ApiPage<String>.fromJson(
        page.toJson((v) => v),
        (j) => j as String,
      );
      expect(decoded, page);
    });
  });

  group('CursorPage (doc §3.2)', () {
    test('parses edges/hasNextPage/endCursor', () {
      final json = {
        'edges': [
          {'id': 'r1'},
        ],
        'hasNextPage': true,
        'endCursor': 'eyJ0Ijoi...',
      };

      final page = CursorPage.fromJson(
        json,
        (j) => (j as Map<String, dynamic>)['id'] as String,
      );

      expect(page.edges, ['r1']);
      expect(page.hasNextPage, isTrue);
      expect(page.endCursor, 'eyJ0Ijoi...');
    });

    test('endCursor absent on last page deserializes to null', () {
      final json = {
        'edges': <Map<String, dynamic>>[],
        'hasNextPage': false,
      };

      final page = CursorPage.fromJson(
        json,
        (j) => (j as Map<String, dynamic>)['id'] as String,
      );

      expect(page.hasNextPage, isFalse);
      expect(page.endCursor, isNull);
    });
  });

  group('BlogPage (doc §3.3)', () {
    test('parses custom blog list wrapper', () {
      final json = {
        'content': [
          {'id': 'b1'},
        ],
        'page': 0,
        'size': 20,
        'totalElements': 5,
        'totalPages': 1,
      };

      final page = BlogPage.fromJson(
        json,
        (j) => (j as Map<String, dynamic>)['id'] as String,
      );

      expect(page.content, ['b1']);
      expect(page.page, 0);
      expect(page.totalElements, 5);
      expect(page.totalPages, 1);
    });
  });
}
