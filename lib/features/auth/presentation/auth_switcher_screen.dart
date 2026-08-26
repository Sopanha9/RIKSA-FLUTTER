import 'dart:async';

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
  static const _toggleDuration = Duration(milliseconds: 250);
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
      child: AutofillGroup(
        child: AnimatedSize(
          duration: _formDuration,
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              AuthPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthSegmentedToggle(
                      pageState: _pageState,
                      enabled: !loading,
                      duration: _toggleDuration,
                      onSelected: _selectPage,
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
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
                    const SizedBox(height: 20),
                    AuthDivider(label: strings.orLabel),
                    const SizedBox(height: 18),
                    SocialAuthSection(
                      isRegistration: _pageState == PageState.register,
                      showDivider: false,
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
      ),
    );
  }
}

class _AuthLoadingOverlay extends StatelessWidget {
  const _AuthLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      liveRegion: true,
      label: strings.preparingYourSpace,
      child: Container(
        decoration: BoxDecoration(
          color: (dark ? colors.surface : AppColors.editorialNeutralSurface)
              .withValues(alpha: .97),
          borderRadius: AppRadii.largeBorder,
          border: Border.all(
            color: dark ? colors.outline : AppColors.editorialOutline,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.editorialPink,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.preparingYourSpace,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _AuthSegmentedToggle extends StatelessWidget {
  const _AuthSegmentedToggle({
    required this.pageState,
    required this.enabled,
    required this.duration,
    required this.onSelected,
  });

  final PageState pageState;
  final bool enabled;
  final Duration duration;
  final ValueChanged<PageState> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? theme.colorScheme.surfaceContainerHighest
            : AppColors.editorialPinkSoft,
        borderRadius: AppRadii.fullBorder,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: .65),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            key: const Key('auth_tab_indicator'),
            duration: duration,
            curve: Curves.easeInOutCubic,
            alignment: pageState == PageState.login
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.editorialPink
                      : AppColors.editorialAubergine,
                  borderRadius: AppRadii.fullBorder,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.editorialPink.withValues(alpha: .24),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ToggleLabel(
                  key: const Key('login_toggle'),
                  label: strings.login,
                  selected: pageState == PageState.login,
                  enabled: enabled,
                  onTap: () => onSelected(PageState.login),
                ),
              ),
              Expanded(
                child: _ToggleLabel(
                  key: const Key('register_toggle'),
                  label: strings.register,
                  selected: pageState == PageState.register,
                  enabled: enabled,
                  onTap: () => onSelected(PageState.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: enabled ? onTap : null,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            style: theme.textTheme.labelLarge!.copyWith(
              color: selected
                  ? (dark
                        ? AppColors.editorialAubergine
                        : const Color(0xFFFFF8FC))
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            child: Text(label),
          ),
        ),
      ),
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
              hintText: strings.emailOrUsernameHint,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
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
              hintText: strings.passwordHint,
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
          const SizedBox(height: 14),
          _AuthSupportNote(
            icon: Icons.shield_outlined,
            label: strings.signInSecureNote,
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
              hintText: strings.usernameHint,
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
              hintText: strings.emailHint,
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
              hintText: strings.passwordHint,
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
              hintText: strings.confirmPasswordHint,
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
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.editorialPink
            : AppColors.editorialAubergine,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.editorialAubergine
            : const Color(0xFFFFF8FC),
        minimumSize: const Size.fromHeight(54),
      ),
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
            : Text(label, key: const ValueKey('label')),
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
      Icon(icon, size: 17, color: AppColors.editorialPink),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.riksa.inkMuted
                : AppColors.editorialMuted,
          ),
        ),
      ),
    ],
  );
}
