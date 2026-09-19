import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleProviderButton({
  required String label,
  required String locale,
  required bool loading,
  required VoidCallback onPressed,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(1, 400).toDouble();
      return IgnorePointer(
        ignoring: loading,
        child: AnimatedOpacity(
          opacity: loading ? .55 : 1,
          duration: const Duration(milliseconds: 160),
          child: SizedBox(
            key: const Key('google_auth_button'),
            height: 52,
            child: Center(
              child: google_web.renderButton(
                configuration: google_web.GSIButtonConfiguration(
                  type: google_web.GSIButtonType.standard,
                  theme: google_web.GSIButtonTheme.outline,
                  size: google_web.GSIButtonSize.large,
                  text: google_web.GSIButtonText.continueWith,
                  shape: google_web.GSIButtonShape.pill,
                  logoAlignment: google_web.GSIButtonLogoAlignment.left,
                  minimumWidth: width,
                  locale: locale,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
