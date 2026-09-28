import 'package:dio/dio.dart';

/// The moderation outcome returned by blog REST and community GraphQL writes.
///
/// Keep this parser independent of widgets so comment composers can reuse it.
enum ModerationRejectionKind { blocked, rateLimited }

class ModerationRejection {
  const ModerationRejection({required this.kind, this.reasons = const []});

  final ModerationRejectionKind kind;

  /// Server reason codes, such as `PROFANITY` or `UNKNOWN_LINK`.
  final List<String> reasons;
}

/// Parses a REST moderation response carried by a [DioException].
///
/// Non-moderation errors return null so callers can preserve their existing
/// error handling.
ModerationRejection? fromDio(DioException error) {
  final data = error.response?.data;
  if (data is! Map) return null;
  return _fromCode(data['code'], data['reasons']);
}

/// Parses moderation details from GraphQL `errors` entries.
///
/// This is public for the community post and comment flows, which receive the
/// moderation code and reason list under `extensions`.
ModerationRejection? fromGraphQlErrors(List<Object?> errors) {
  for (final error in errors) {
    if (error is! Map) continue;
    final extensions = error['extensions'];
    if (extensions is! Map) continue;
    final rejection = _fromCode(extensions['code'], extensions['reasons']);
    if (rejection != null) return rejection;
  }
  return null;
}

ModerationRejection? _fromCode(Object? code, Object? rawReasons) {
  final kind = switch (code) {
    'CONTENT_BLOCKED' => ModerationRejectionKind.blocked,
    'RATE_LIMITED' => ModerationRejectionKind.rateLimited,
    _ => null,
  };
  if (kind == null) return null;

  final reasons = rawReasons is List
      ? rawReasons.whereType<String>().toList(growable: false)
      : const <String>[];
  return ModerationRejection(kind: kind, reasons: reasons);
}
