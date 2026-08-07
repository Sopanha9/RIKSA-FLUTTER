import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

/// Spring `Page<T>` offset pagination wrapper (doc §3.1).
///
/// Used by: users, lessons, posts, comments, audit logs.
/// Named `ApiPage` to avoid clashing with Flutter's `Page` widget.
@Freezed(genericArgumentFactories: true, makeCollectionsUnmodifiable: false)
abstract class ApiPage<T> with _$ApiPage<T> {
  const factory ApiPage({
    required List<T> content,
    required int number,
    required int size,
    required int totalElements,
    required int totalPages,
    required bool first,
    required bool last,
    required bool empty,
  }) = _ApiPage<T>;

  factory ApiPage.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiPageFromJson(json, fromJsonT);
}
