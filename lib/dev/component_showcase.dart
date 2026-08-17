import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_avatar.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_snack_bar.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_state.dart';
import '../core/widgets/google_logo.dart';
import '../core/widgets/image_with_fallback.dart';
import '../core/widgets/labeled_divider.dart';
import '../core/widgets/language_toggle.dart';
import '../core/widgets/password_field.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/secondary_button.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/skeleton_box.dart';
import '../core/widgets/social_button.dart';
import '../core/widgets/telegram_logo.dart';

void main() => runApp(const ComponentShowcaseApp());

class ComponentShowcaseApp extends StatelessWidget {
  const ComponentShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const ShowcaseScreen(),
      ),
    );
  }
}

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Component Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(title: 'Buttons'),
          SizedBox(height: 12),
          PrimaryButton(label: 'Primary button'),
          SizedBox(height: 8),
          PrimaryButton(label: 'Loading...', loading: true),
          SizedBox(height: 8),
          SecondaryButton(label: 'Secondary button'),
          SizedBox(height: 8),
          SecondaryButton(label: 'Loading...', loading: true),
          SizedBox(height: 8),
          Row(
            children: [
              SocialButton(
                logo: GoogleLogo(size: 28),
                onPressed: _noop,
              ),
              SizedBox(width: 12),
              SocialButton(
                logo: TelegramLogo(size: 28),
                onPressed: _noop,
              ),
            ],
          ),
          SizedBox(height: 24),
          SectionHeader(title: 'Navigation'),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Language toggle'),
              LanguageToggle(),
            ],
          ),
          SizedBox(height: 24),
          SectionHeader(title: 'Inputs'),
          SizedBox(height: 12),
          AppTextField(
            label: 'Username',
            hint: 'Enter your username',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: 12),
          PasswordField(label: 'Password', hint: 'Enter your password'),
          SizedBox(height: 24),
          SectionHeader(title: 'Feedback'),
          SizedBox(height: 12),
          EmptyState(
            title: 'Nothing here yet',
            message: 'Start creating content and it will show up here.',
            actionLabel: 'Create',
          ),
          SizedBox(height: 12),
          ErrorState(
            message: 'Could not load your data. Check your connection.',
            onRetry: _noop,
          ),
          SizedBox(height: 12),
          SkeletonBox(),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonBox(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Builder(
            builder: (context) => PrimaryButton(
              label: 'Show snackbars',
              onPressed: () => _showSnackbars(context),
            ),
          ),
          SizedBox(height: 24),
          SectionHeader(title: 'Layout'),
          SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                AppAvatar(name: 'Sok Dara', size: 44),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sok Dara',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Student', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          LabeledDivider(label: 'or continue with'),
          SizedBox(height: 24),
          SectionHeader(title: 'Media'),
          SizedBox(height: 12),
          Row(
            children: [
              AppAvatar(name: 'Riksa Learner'),
              SizedBox(width: 8),
              AppAvatar(name: 'Chanthy Sreymom', size: 56),
            ],
          ),
          SizedBox(height: 12),
          ImageWithFallback(
            imageUrl: 'https://example.com/nonexistent.png',
            width: double.infinity,
            height: 120,
          ),
        ],
      ),
    );
  }
}

void _noop() {}

void _showSnackbars(BuildContext context) {
  showAppSnackBar(context, 'This is a normal snackbar');
  final messenger = ScaffoldMessenger.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  Future.delayed(
    const Duration(seconds: 2),
    () => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('This is an error snackbar'),
          backgroundColor: colorScheme.error,
        ),
      ),
  );
}
