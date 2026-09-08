import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Optional inspection export. This never accepts or rewrites a golden.
Future<void> exportAchievementPreview(
  WidgetTester tester,
  Finder finder,
  String name,
) async {
  if (Platform.environment['EXPORT_ACHIEVEMENT_PREVIEWS'] != '1') return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'docs/achievement-artwork/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> loadAchievementPreviewFonts() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  for (final entry in {
    'Poppins': 'assets/fonts/Poppins-Regular.ttf',
    'Kantumruy Pro': 'assets/fonts/KantumruyPro-Variable.ttf',
    'MaterialIcons':
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  }.entries) {
    await (FontLoader(entry.key)
          ..addFont(File(entry.value).readAsBytes().then(ByteData.sublistView)))
        .load();
  }
}
