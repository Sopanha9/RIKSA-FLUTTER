import 'package:freezed_annotation/freezed_annotation.dart';

part 'cursor_page.freezed.dart';
part 'cursor_page.g.dart';

/// Cursor pagination wrapper (doc §3.2).
///
/// Used by: reports list.
/// [endCursor] is ABSENT (not null) on the last page — treat it as opaque;
/// never decode or build cursors yourself.
@Freezed(genericArgumentFactories: true, makeCollectionsUnmodifiable: false)
abstract class CursorPage<T> with _$CursorPage<T> {
  const factory CursorPage({
    required List<T> edges,
    required bool hasNextPage,
    String? endCursor,
  }) = _CursorPage<T>;

  factory CursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$CursorPageFromJson(json, fromJsonT);
}
