import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_brand.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/auth_models.dart';
import '../data/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_section.dart';

enum PageState { login, register }

/// A single, reusable authentication surface with animated login/register
/// switching. Form controllers live here so neither form loses entered values
/// while it is temporarily removed from the widget tree.
class AuthSwitcherScreen extends ConsumerStatefulWidget {
  const AuthSwitcherScreen({
    super.key,
    this.initialPage = PageState.login,
    this.onForgotPassword,
  });

  final PageState initialPage;
  final VoidCallback? onForgotPassword;

  @override
  ConsumerState<AuthSwitcherScreen> createState() => _AuthSwitcherScreenState();
}

class _AuthSwitcherScreenState extends ConsumerState<AuthSwitcherScreen> {
  static const _formDuration = Duration(milliseconds: 300);

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmationController = TextEditingController();

  late PageState _pageState;
  Timer? _animationGuard;
  bool _isAnimating = false;
  int _switchDirection = 1;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmation = true;

  @override
  void initState() {
    super.initState();
    _pageState = widget.initialPage;
  }

  @override
  void didUpdateWidget(covariant AuthSwitcherScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage && !_isAnimating) {
      _selectPage(widget.initialPage);
    }
  }

  @override
  void dispose() {
    _animationGuard?.cancel();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmationController.dispose();
    super.dispose();
  }

  void _selectPage(PageState next) {
    if (_pageState == next || _isAnimating) return;
    if (ref.read(authProvider) is AuthLoading) return;

    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(authProvider.notifier).clearError();
    _animationGuard?.cancel();

    setState(() {
      _switchDirection = next == PageState.register ? 1 : -1;
      _pageState = next;
      _isAnimating = true;
    });

    _animationGuard = Timer(_formDuration, () {
      if (mounted) setState(() => _isAnimating = false);
    });
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authProvider.notifier)
        .login(
          username: _loginIdentifierController.text.trim(),
          password: _loginPasswordController.text,
        );
  }

  Future<void> _submitRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    final username = _registerUsernameController.text.trim();
    await ref
        .read(authProvider.notifier)
        .register(
          RegisterRequest(
            username: username,
            displayName: _displayNameFrom(username),
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
          ),
        );
  }

  String _displayNameFrom(String username) {
    final words = username
        .split(RegExp(r'[._\-\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return words.isEmpty ? username : words;
  }

  void _forgotPassword() {
    final callback = widget.onForgotPassword;
    if (callback != null) {
      callback();
      return;
    }

    final strings = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(strings.passwordRecoveryUnavailable)),
      );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final childPage = (child.key as ValueKey<PageState>).value;
    final isIncoming = childPage == _pageState;
    final horizontalOffset =
        (isIncoming ? _switchDirection : -_switchDirection) * .12;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(horizontalOffset, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
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
      showLanguageToggle: true,
      child: AutofillGroup(
        child: Stack(
          children: [
            AuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: RiksaWordmark(fontSize: 46),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSize(
                    duration: _formDuration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: _formDuration,
                      reverseDuration: _formDuration,
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: _buildTransition,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previousChildren, ?currentChild],
                      ),
                      child: _pageState == PageState.login
                          ? _LoginForm(
                              key: const ValueKey(PageState.login),
                              formKey: _loginFormKey,
                              identifierController: _loginIdentifierController,
                              passwordController: _loginPasswordController,
                              obscurePassword: _obscureLoginPassword,
                              loading: loading,
                              error: error,
                              onTogglePassword: () => setState(
                                () => _obscureLoginPassword =
                                    !_obscureLoginPassword,
                              ),
                              onForgotPassword: _forgotPassword,
                              onSubmit: _submitLogin,
                            )
                          : _RegisterForm(
                              key: const ValueKey(PageState.register),
                              formKey: _registerFormKey,
                              usernameController: _registerUsernameController,
                              emailController: _registerEmailController,
                              passwordController: _registerPasswordController,
                              confirmationController:
                                  _registerConfirmationController,
                              obscurePassword: _obscureRegisterPassword,
                              obscureConfirmation: _obscureRegisterConfirmation,
                              loading: loading,
                              error: error,
                              onTogglePassword: () => setState(
                                () => _obscureRegisterPassword =
                                    !_obscureRegisterPassword,
                              ),
                              onToggleConfirmation: () => setState(
                                () => _obscureRegisterConfirmation =
                                    !_obscureRegisterConfirmation,
                              ),
                              onSubmit: _submitRegistration,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthDivider(label: strings.orContinueWith),
                  const SizedBox(height: 18),
                  SocialAuthSection(
                    showDivider: false,
                    compact: _pageState == PageState.login,
                  ),
                  const SizedBox(height: 28),
                  _AuthSwitchPrompt(
                    pageState: _pageState,
                    enabled: !loading,
                    onSelected: _selectPage,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: loading
                    ? const _AuthLoadingOverlay(
                        key: Key('auth_loading_overlay'),
                      )
                    : const SizedBox(key: Key('auth_loading_idle')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLoadingOverlay extends StatelessWidget {
  const _AuthLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Semantics(
      liveRegion: true,
      label: strings.preparingYourSpace,
      child: Container(
        decoration: BoxDecoration(
          color: palette.canvas.withValues(alpha: .8),
          borderRadius: AppRadii.largeBorder,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 24, 12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadii.fullBorder,
              border: Border.all(color: palette.outline),
              boxShadow: RiksaElevation.low(theme.brightness),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RiksaMascot(size: 44, showSparkles: false),
                const SizedBox(width: 10),
                SizedBox.square(
                  key: const Key('auth_loading_animation'),
                  dimension: 30,
                  child: LoadingAnimationWidget.twistingDots(
                    leftDotColor: palette.brand,
                    rightDotColor: AppColors.lime,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    strings.preparingYourSpace,
                    textAlign: TextAlign.center,
                    style: RiksaTypography.bodyStyleFor(
                      strings.preparingYourSpace,
                      theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" under the login form, and the way back
/// under the registration form.
class _AuthSwitchPrompt extends StatelessWidget {
  const _AuthSwitchPrompt({
    required this.pageState,
    required this.enabled,
    required this.onSelected,
  });

  final PageState pageState;
  final bool enabled;
  final ValueChanged<PageState> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final login = pageState == PageState.login;
    final question = login ? strings.noAccount : strings.haveAccount;
    final action = login ? strings.signUpNow : strings.login;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: RiksaTypography.bodyStyleFor(
            question,
            theme.textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
          ),
        ),
        TextButton(
          key: Key(login ? 'register_toggle' : 'login_toggle'),
          onPressed: enabled
              ? () => onSelected(login ? PageState.register : PageState.login)
              : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 40),
          ),
          child: Text(
            action,
            style: RiksaTypography.bodyStyleFor(
              action,
              const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.error,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: strings.welcomeBack,
            subtitle: strings.loginSubtitle,
          ),
          const SizedBox(height: 22),
          if (error != null) ...[
            AuthErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('login_username'),
            controller: identifierController,
            enabled: !loading,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: strings.emailOrUsername,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
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
            controller: passwordController,
            enabled: !loading,
            autofillHints: const [AutofillHints.password],
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: strings.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: loading ? null : onTogglePassword,
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
              return null;
            },
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('forgot_password'),
              onPressed: loading ? null : onForgotPassword,
              child: Text(strings.forgotPassword),
            ),
          ),
          const SizedBox(height: 4),
          _AuthSubmitButton(
            buttonKey: const Key('login_submit'),
            loading: loading,
            label: strings.login,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmationController,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.loading,
    required this.error,
    required this.onTogglePassword,
    required this.onToggleConfirmation,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final bool obscurePassword;
  final bool obscureConfirmation;
  final bool loading;
  final String? error;
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
          AuthHeader(
            title: strings.registerTitle,
            subtitle: strings.registerSubtitle,
          ),
          const SizedBox(height: 22),
          if (error != null) ...[
            AuthErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('register_username'),
            controller: usernameController,
            enabled: !loading,
            autofillHints: const [AutofillHints.newUsername],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 50,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.username,
              prefixIcon: const Icon(Icons.person_outline_rounded),
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
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('register_email'),
            controller: emailController,
            enabled: !loading,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.email,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
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
          TextFormField(
            key: const Key('register_password'),
            controller: passwordController,
            enabled: !loading,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: obscurePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: loading ? null : onTogglePassword,
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
          const SizedBox(height: 14),
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
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: loading ? null : onToggleConfirmation,
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
          const SizedBox(height: 20),
          _AuthSubmitButton(
            buttonKey: const Key('register_submit'),
            loading: loading,
            label: strings.register,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 14),
          _AuthSupportNote(
            icon: Icons.mark_email_read_outlined,
            label: strings.registerEmailNote,
          ),
        ],
      ),
    );
  }
}

class _AuthSubmitButton extends StatelessWidget {
  const _AuthSubmitButton({
    required this.buttonKey,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Text(label, key: const ValueKey('label')),
      ),
    );
  }
}

class _AuthSupportNote extends StatelessWidget {
  const _AuthSupportNote({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: context.riksa.brand),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.riksa.inkMuted),
        ),
      ),
    ],
  );
}
