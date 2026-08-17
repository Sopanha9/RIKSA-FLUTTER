import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_section.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final loading = auth is AuthLoading;
    final error = auth is AuthError ? auth.message : null;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated) {
        TextInput.finishAutofillContext();
        context.go('/home');
      }
    });

    return AuthScaffold(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.welcomeBack,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onBackground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SocialAuthSection(
                    isRegistration: false,
                    showDivider: false,
                  ),
                  const SizedBox(height: 18),
                  AuthDivider(label: strings.orLabel),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          AuthErrorBanner(message: error),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          key: const Key('login_username'),
                          controller: _usernameController,
                          enabled: !loading,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: strings.username,
                            hintText: strings.usernameHint,
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return strings.requiredField;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('login_password'),
                          controller: _passwordController,
                          enabled: !loading,
                          autofillHints: const [AutofillHints.password],
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: strings.password,
                            hintText: strings.passwordHint,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              tooltip: _obscurePassword
                                  ? strings.showPassword
                                  : strings.hidePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return strings.requiredField;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const Key('login_submit'),
                          onPressed: loading ? null : _submit,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: loading
                                ? const SizedBox.square(
                                    key: ValueKey('loading'),
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    strings.login,
                                    key: const ValueKey('label'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    strings.noAccount,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => context.push('/auth/register'),
                  child: Text(strings.signUpNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
