import 'api_config.dart';

/// Help and legal pages, served by the backend as plain web pages so they can
/// change without an app release.
abstract final class SupportDocuments {
  static String get faq => _page('faq');
  static String get termsOfService => _page('terms');
  static String get privacyPolicy => _page('privacy');
  static String get communityAgreement => _page('agreement');

  static String _page(String name) => '${ApiConfig.baseUrl}/legal/$name.html';
}
