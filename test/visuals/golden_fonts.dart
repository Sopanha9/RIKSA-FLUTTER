import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real fonts, Reddit Sans included, so goldens show
/// the hierarchy the device shows.
Future<void> loadRiksaGoldenFonts() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  await (FontLoader('MaterialIcons')..addFont(
        File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then(ByteData.sublistView),
      ))
      .load();
  final redditSans = FontLoader('Reddit Sans')
    ..addFont(rootBundle.load('assets/fonts/RedditSans-Variable.ttf'));
  await redditSans.load();
  for (final entry in {
    'Kantumruy Pro': 'assets/fonts/KantumruyPro-Variable.ttf',
    'Khmer OS Siemreap': 'assets/fonts/KhmerOS_siemreap.ttf',
    'Noto Sans Khmer': 'assets/fonts/NotoSansKhmer-Variable.ttf',
    'Koulen': 'assets/fonts/Koulen-Regular.ttf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}
