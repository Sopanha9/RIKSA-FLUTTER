import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app (for example a `t.me` bot link, which the OS
/// hands to the Telegram app when installed). Returns false when nothing could
/// handle it. Overridden in tests.
typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

final externalLinkOpenerProvider = Provider<ExternalLinkOpener>((ref) {
  return (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  };
});
