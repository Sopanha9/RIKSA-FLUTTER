import 'package:flutter/widgets.dart';

import '../network/moderation_error.dart';
import '../../l10n/gen/app_localizations.dart';

/// Returns the localized, user-facing sentence for a moderation rejection.
///
/// Use this shared helper for post and comment composers so server reason
/// codes are presented consistently in the active app language.
String moderationMessage(BuildContext context, ModerationRejection rejection) {
  final l10n = AppLocalizations.of(context)!;
  if (rejection.kind == ModerationRejectionKind.rateLimited) {
    return l10n.moderationRateLimited;
  }

  final reasons = rejection.reasons.toSet();
  if (reasons.contains('PROFANITY')) return l10n.moderationProfanity;
  if (reasons.any(
    (reason) =>
        reason == 'SPAM_LINKS' ||
        reason == 'UNKNOWN_LINK' ||
        reason == 'LINK_ONLY',
  )) {
    return l10n.moderationLinks;
  }
  if (reasons.contains('DUPLICATE')) return l10n.moderationDuplicate;
  if (reasons.contains('SHOUTING') || reasons.contains('REPEATED_CHARS')) {
    return l10n.moderationShouting;
  }
  return l10n.moderationFallback;
}
