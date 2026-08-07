import 'package:freezed_annotation/freezed_annotation.dart';

part 'blog_page.freezed.dart';
part 'blog_page.g.dart';

/// Custom blog moderation list wrapper (doc §3.3 / §10.1).
///
/// Simpler than Spring's `Page<T>`: no `first`/`last`/`empty` flags.
@Freezed(genericArgumentFactories: true, makeCollectionsUnmodifiable: false)
abstract class BlogPage<T> with _$BlogPage<T> {
  const factory BlogPage({
    required List<T> content,
    required int page,
    required int size,
    required int totalElements,
    required int totalPages,
  }) = _BlogPage<T>;

  factory BlogPage.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BlogPageFromJson(json, fromJsonT);
}
