import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_design.dart';
import 'package:riksa_app/features/learning/presentation/roadmap_stones.dart';

/// Parses a real `GET /api/v1/lessons/roadmap` response, captured verbatim from
/// the running Spring backend.
///
/// This exists because the client previously parsed a `lessons` array that the
/// endpoint has never returned. Every subject silently rendered as empty, and
/// no hand written fixture caught it, because the fixtures agreed with the
/// client instead of with the server. Re-capture this file whenever the
/// endpoint's shape changes; if it drifts, this test fails instead of the app
/// quietly showing nothing.
void main() {
  late Map<String, dynamic> json;

  setUpAll(() {
    json =
        jsonDecode(
              File(
                'test/fixtures/lessons_roadmap_mathematics.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  test('the captured response is unit shaped, not lesson shaped', () {
    expect(
      json.containsKey('units'),
      isTrue,
      reason: 'the endpoint groups the syllabus into units',
    );
    expect(
      json.containsKey('lessons'),
      isFalse,
      reason: 'there is no top level lessons array to parse',
    );
  });

  test('LearningRoadmap reads every unit and lesson the server sent', () {
    final roadmap = LearningRoadmap.fromJson(json);

    expect(roadmap.categoryName, 'Mathematics');
    expect(roadmap.units, isNotEmpty);
    expect(roadmap.totalLessons, greaterThan(0));
    expect(
      roadmap.units.fold(0, (sum, unit) => sum + unit.lessons.length),
      roadmap.totalLessons,
      reason: 'no lesson may be dropped while flattening the units',
    );
    expect(roadmap.progress, inInclusiveRange(0, 1));

    // Khmer lesson titles survive the round trip intact.
    final titles = roadmap.units
        .expand((unit) => unit.lessons)
        .map((lesson) => lesson.title);
    expect(titles.any(RiksaTypographyProbe.containsKhmer), isTrue);
  });

  test('the spine keeps the server ordering and gating', () {
    final roadmap = LearningRoadmap.fromJson(json);
    final stones = buildRoadmapStones(roadmap);

    expect(stones.length, roadmap.units.length);
    expect(
      stones.map((stone) => stone.index),
      List.generate(stones.length, (index) => index + 1),
    );

    // Lesson numbering runs across the whole subject.
    final numbers = stones
        .expand((stone) => stone.lessons)
        .map((lesson) => lesson.index)
        .toList();
    expect(numbers, List.generate(numbers.length, (index) => index + 1));

    // A locked unit is never openable, and the server gates at least one.
    expect(
      stones.any((stone) => stone.status == LearningStatus.locked),
      isTrue,
      reason: 'the seeded syllabus gates later units',
    );
    for (final stone in stones.where(
      (stone) => stone.status == LearningStatus.locked,
    )) {
      expect(stone.isOpenable, isFalse);
    }
  });

  test('the header totals match the server totals exactly', () {
    final roadmap = LearningRoadmap.fromJson(json);
    final summary = RoadmapSummary.of(roadmap, buildRoadmapStones(roadmap));

    expect(summary.completed, json['completedLessons']);
    expect(summary.total, json['totalLessons']);
    expect(summary.totalUnits, (json['units'] as List).length);
  });
}

/// Small indirection so this test does not reach into the theme layer just to
/// check a script range.
abstract final class RiksaTypographyProbe {
  static final _khmer = RegExp(r'[ក-៿]');
  static bool containsKhmer(String value) => _khmer.hasMatch(value);
}
