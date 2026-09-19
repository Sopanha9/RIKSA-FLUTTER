import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/auth_models.dart';
import '../data/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_section.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _basicsKey = GlobalKey<FormState>();
  final _securityKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_basicsKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_securityKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .register(
          RegisterRequest(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _back() {
    if (_step == 1) {
      ref.read(authProvider.notifier).clearError();
      setState(() => _step = 0);
    }
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
      expandedHeaderMinHeight: 780,
      onBack: _step == 1 && !loading ? _back : null,
      footer: AuthAccountPrompt(
        prompt: strings.haveAccount,
        label: strings.signInNow,
        onTap: loading ? null : () => context.pop(),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.registerTitle,
                    textAlign: TextAlign.center,
                    style: AuthTextStyles.heading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: AuthTextStyles.supporting,
                  ),
                  const SizedBox(height: 10),
                  _StepIndicator(
                    step: _step,
                    label: strings.stepOfTwo(_step + 1),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _BasicsStep(
                            key: const ValueKey('basics'),
                            formKey: _basicsKey,
                            usernameController: _usernameController,
                            displayNameController: _displayNameController,
                            emailController: _emailController,
                            onContinue: _continue,
                          )
                        : _SecurityStep(
                            key: const ValueKey('security'),
                            formKey: _securityKey,
                            passwordController: _passwordController,
                            confirmationController: _confirmPasswordController,
                            obscurePassword: _obscurePassword,
                            obscureConfirmation: _obscureConfirmation,
                            loading: loading,
                            error: error,
                            onPasswordChanged: (_) => setState(() {}),
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            onToggleConfirmation: () => setState(
                              () =>
                                  _obscureConfirmation = !_obscureConfirmation,
                            ),
                            onSubmit: _submit,
                          ),
                  ),
                  const SizedBox(height: 12),
                  AuthDivider(label: strings.orLabel),
                  const SizedBox(height: 10),
                  const SocialAuthSection(
                    isRegistration: true,
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: step == 0 ? .5 : 1,
              minHeight: 3,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .08),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.displayNameController,
    required this.emailController,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('register_username'),
            controller: usernameController,
            autofillHints: const [AutofillHints.newUsername],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 50,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.username,
              hintText: strings.usernameHint,
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.requiredField;
              }
              if (!AuthValidators.isRegistrationUsername(value)) {
                return strings.usernameTooLong;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('register_display_name'),
            controller: displayNameController,
            autofillHints: const [AutofillHints.name],
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.displayName,
              hintText: strings.displayNameHint,
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.requiredField;
              }
              if (!AuthValidators.isDisplayName(value)) {
                return strings.displayNameTooLong;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('register_email'),
            controller: emailController,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onContinue(),
            decoration: InputDecoration(
              labelText: strings.email,
              hintText: strings.emailHint,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.requiredField;
              }
              if (!AuthValidators.isEmail(value)) return strings.invalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('register_continue'),
            onPressed: onContinue,
            label: Text(strings.continueLabel),
          ),
        ],
      ),
    );
  }
}

class _SecurityStep extends StatelessWidget {
  const _SecurityStep({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmationController,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.loading,
    required this.error,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmation,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final bool obscurePassword;
  final bool obscureConfirmation;
  final bool loading;
  final String? error;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmation;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            AuthErrorText(message: error!),
            const SizedBox(height: 10),
          ],
          TextFormField(
            key: const Key('register_password'),
            controller: passwordController,
            enabled: !loading,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: onPasswordChanged,
            decoration: InputDecoration(
              labelText: strings.password,
              hintText: strings.passwordHint,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: obscurePassword
                    ? strings.showPassword
                    : strings.hidePassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return strings.requiredField;
              }
              if (!AuthValidators.isStrongPassword(value)) {
                return strings.weakPassword;
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          PasswordRequirements(password: passwordController.text),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('register_confirm_password'),
            controller: confirmationController,
            enabled: !loading,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: obscureConfirmation,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: strings.confirmPassword,
              hintText: strings.confirmPasswordHint,
              suffixIcon: IconButton(
                onPressed: onToggleConfirmation,
                icon: Icon(
                  obscureConfirmation
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: obscureConfirmation
                    ? strings.showPassword
                    : strings.hidePassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return strings.requiredField;
              }
              if (value != passwordController.text) {
                return strings.passwordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('register_submit'),
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(strings.register),
          ),
        ],
      ),
    );
  }
}
