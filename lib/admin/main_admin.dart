import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_app.dart';

void main() {
  if (!kIsWeb) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Admin dashboard is only available on web.'),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: AdminApp()));
}
