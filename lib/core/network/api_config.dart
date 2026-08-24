import 'package:flutter/foundation.dart';

/// Riksa API base configuration.
class ApiConfig {
  ApiConfig._();

  /// Local dev backend. Override via -Ddart-define=API_BASE_URL=...
  ///
  /// Defaults to the host-loopback address that works on each dev target:
  /// Android emulator aliases the host as 10.0.2.2, while iOS simulator /
  /// macOS / desktop reach it directly as localhost.
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String apiPrefix = '/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}