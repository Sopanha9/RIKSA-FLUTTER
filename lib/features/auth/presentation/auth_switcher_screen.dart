import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/riksa_brand.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_speech.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/mascot_provider.dart';
import '../data/auth_models.dart';
import '../data/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_section.dart';

enum PageState { login, register }

class _AuthScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _AuthScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
    );
  }
}

class _AuthScrollPosition extends ScrollPositionWithSingleContext {
  _AuthScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
  });

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    final notificationContext = context.notificationContext;
    final bool disableAnimations =
        notificationContext != null &&
        (MediaQuery.maybeDisableAnimationsOf(notificationContext) ?? false);
    if (disableAnimations) {
      jumpTo(to);
      return Future<void>.value();
    }
    return super.animateTo(to, duration: duration, curve: curve);
  }
}

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
  final _loginIdentifierFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  final _registerUsernameFocus = FocusNode();
  final _registerEmailFocus = FocusNode();
  final _registerPasswordFocus = FocusNode();
  final _registerConfirmationFocus = FocusNode();
  final _mascotController = MascotController();
  final _scrollController = _AuthScrollController();

  late PageState _pageState;
  Timer? _animationGuard;
  bool _isAnimating = false;
  int _switchDirection = 1;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmation = true;
  _BuddyFeedback _buddyFeedback = _BuddyFeedback.none;
  String? _buddyError;
  int _failureCount = 0;
  int _passwordShake = 0;
  String _authenticatedLocation = kLandingLocation;

  @override
  void initState() {
    super.initState();
    _pageState = widget.initialPage;
    for (final focus in _focusNodes) {
      focus.addListener(_handleFocusChange);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mascotController.react(MascotMood.greeting);
    });
  }

  List<FocusNode> get _focusNodes => [
    _loginIdentifierFocus,
    _loginPasswordFocus,
    _registerUsernameFocus,
    _registerEmailFocus,
    _registerPasswordFocus,
    _registerConfirmationFocus,
  ];

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
    for (final focus in _focusNodes) {
      focus
        ..removeListener(_handleFocusChange)
        ..dispose();
    }
    _mascotController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _passwordHasFocus => _pageState == PageState.login
      ? _loginPasswordFocus.hasFocus
      : _registerPasswordFocus.hasFocus || _registerConfirmationFocus.hasFocus;

  bool get _passwordIsObscured => _pageState == PageState.login
      ? _obscureLoginPassword
      : _registerPasswordFocus.hasFocus
      ? _obscureRegisterPassword
      : _obscureRegisterConfirmation;

  bool get _identifierHasFocus => _pageState == PageState.login
      ? _loginIdentifierFocus.hasFocus
      : _registerUsernameFocus.hasFocus || _registerEmailFocus.hasFocus;

  void _handleFocusChange() {
    if (!mounted) return;
    _buddyFeedback = _BuddyFeedback.none;
    _buddyError = null;
    _syncRestingMood();
    setState(() {});
  }

  void _syncRestingMood() {
    if (ref.read(authProvider) is AuthLoading) {
      _mascotController.mood = MascotMood.thinking;
    } else if (_passwordHasFocus) {
      _mascotController.mood = _passwordIsObscured
          ? MascotMood.sleep
          : MascotMood.happy;
    } else if (_identifierHasFocus) {
      _mascotController.mood = MascotMood.thinking;
    } else {
      _mascotController.mood = MascotMood.idle;
    }
  }

  void _showValidationHint() {
    setState(() {
      _buddyFeedback = _BuddyFeedback.validation;
      _buddyError = null;
    });
    _mascotController.react(MascotMood.thinking);
  }

  void _togglePassword(VoidCallback toggle) {
    setState(toggle);
    _syncRestingMood();
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
      _buddyFeedback = _BuddyFeedback.none;
      _buddyError = null;
    });
    _mascotController.react(MascotMood.greeting);

    _animationGuard = Timer(_formDuration, () {
      if (mounted) setState(() => _isAnimating = false);
    });
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      _showValidationHint();
      return;
    }

    await ref
        .read(authProvider.notifier)
        .login(
          username: _loginIdentifierController.text.trim(),
          password: _loginPasswordController.text,
        );
  }

  Future<void> _submitRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) {
      _showValidationHint();
      return;
    }

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

  String _buddyLine(AppLocalizations strings, String name, bool loading) {
    if (_buddyFeedback == _BuddyFeedback.success) {
      return strings.authBuddySuccess;
    }
    if (loading) return strings.authBuddyChecking;
    if (_buddyFeedback == _BuddyFeedback.error) {
      return _failureCount >= 3
          ? strings.authBuddyForgotHint
          : strings.authBuddyError(_buddyError ?? '');
    }
    if (_buddyFeedback == _BuddyFeedback.validation) {
      return strings.authBuddyValidationHint;
    }
    if (_passwordHasFocus) {
      return _passwordIsObscured
          ? strings.authBuddyPasswordHidden
          : strings.authBuddyPasswordShown;
    }
    return _pageState == PageState.login
        ? strings.authBuddyWelcome(name)
        : strings.authBuddyRegister;
  }

  void _onAuthChanged(AuthState? previous, AuthState next) {
    if (next is AuthLoading) {
      _mascotController.mood = MascotMood.thinking;
      return;
    }
    if (next is AuthError) {
      setState(() {
        _failureCount++;
        _buddyFeedback = _BuddyFeedback.error;
        _buddyError = next.message;
        _passwordShake++;
      });
      _mascotController.react(MascotMood.sad);
      return;
    }
    if (next is Authenticated) {
      unawaited(_finishSuccessfulAuthentication());
      return;
    }
    _syncRestingMood();
  }

  Future<void> _finishSuccessfulAuthentication() async {
    TextInput.finishAutofillContext();
    setState(() => _buddyFeedback = _BuddyFeedback.success);
    _mascotController.react(MascotMood.celebrate);
    final delay = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (mounted && ref.read(authProvider) is Authenticated) {
      context.go(_authenticatedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? reasonCopy;
    try {
      final route = GoRouterState.of(context);
      if (route.matchedLocation.startsWith('/auth')) {
        _authenticatedLocation = authenticatedLandingFor(route.uri);
        final strings = AppLocalizations.of(context)!;
        reasonCopy = switch (route.uri.queryParameters['reason']) {
          'save_progress' => strings.authReasonSaveProgress,
          'save_lesson' => strings.authReasonSaveLesson,
          'post' => strings.authReasonPost,
          _ => null,
        };
      }
    } on GoError {
      // AuthSwitcherScreen is also used outside a router in widget previews.
    }
    final strings = AppLocalizations.of(context)!;
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;
    final auth = ref.watch(authProvider);
    final loading = auth is AuthLoading;
    final error = auth is AuthError ? auth.message : null;
    final mascot = ref.watch(mascotProvider).profile;
    final species = mascot?.species ?? MascotSpecies.crocodile;
    final name = mascot?.name ?? MascotProfile.defaultName(species);
    final duration = RiksaMotion.resolve(context, _formDuration);

    ref.listen<AuthState>(authProvider, _onAuthChanged);

    final formSwitcher = AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: _buildTransition,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: _pageState == PageState.login
          ? _LoginForm(
              key: const ValueKey(PageState.login),
              formKey: _loginFormKey,
              identifierController: _loginIdentifierController,
              passwordController: _loginPasswordController,
              identifierFocus: _loginIdentifierFocus,
              passwordFocus: _loginPasswordFocus,
              obscurePassword: _obscureLoginPassword,
              passwordShake: _passwordShake,
              loading: loading,
              error: error,
              reasonCopy: reasonCopy,
              onTogglePassword: () => _togglePassword(
                () => _obscureLoginPassword = !_obscureLoginPassword,
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
              confirmationController: _registerConfirmationController,
              usernameFocus: _registerUsernameFocus,
              emailFocus: _registerEmailFocus,
              passwordFocus: _registerPasswordFocus,
              confirmationFocus: _registerConfirmationFocus,
              obscurePassword: _obscureRegisterPassword,
              obscureConfirmation: _obscureRegisterConfirmation,
              passwordShake: _passwordShake,
              loading: loading,
              error: error,
              onTogglePassword: () => _togglePassword(
                () => _obscureRegisterPassword = !_obscureRegisterPassword,
              ),
              onToggleConfirmation: () => _togglePassword(
                () => _obscureRegisterConfirmation =
                    !_obscureRegisterConfirmation,
              ),
              onSubmit: _submitRegistration,
            ),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.riksa.canvas,
        body: Stack(
          children: [
            Positioned.fill(child: MascotSceneBackdrop(species: species)),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    // The header keeps the language toggle's height, so a
                    // back arrow never moves the form below it.
                    child: Stack(
                      alignment: AlignmentDirectional.centerStart,
                      clipBehavior: Clip.none,
                      children: [
                        const Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: LanguageToggle(),
                        ),
                        if (_pageState == PageState.register || canPop)
                          // Positioned, so its 44px target doesn't set the
                          // header's height.
                          PositionedDirectional(
                            start: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: RiksaBackButton(
                                key: ValueKey(
                                  _pageState == PageState.register
                                      ? 'auth-register-back'
                                      : 'auth-login-back',
                                ),
                                fallbackLocation:
                                    _pageState == PageState.register
                                    ? '/auth/login'
                                    : '/learn',
                                constraints: const BoxConstraints.tightFor(
                                  width: 44,
                                  height: 44,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: context.riksa.ink,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _AuthBuddyStrip(
                  species: species,
                  controller: _mascotController,
                  line: _buddyLine(strings, name, loading),
                ),
                Expanded(
                  child: MascotSceneSheet(
                    child: Stack(
                      children: [
                        AutofillGroup(
                          child: CustomScrollView(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            slivers: [
                              SliverToBoxAdapter(
                                child: AuthPanel(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: RiksaWordmark(fontSize: 32),
                                      ),
                                      const SizedBox(height: 16),
                                      duration == Duration.zero
                                          ? formSwitcher
                                          : AnimatedSize(
                                              duration: duration,
                                              curve: Curves.easeInOutCubic,
                                              alignment: Alignment.topCenter,
                                              child: formSwitcher,
                                            ),
                                      const SizedBox(height: 22),
                                      AuthDivider(
                                        label: strings.orContinueWith,
                                      ),
                                      const SizedBox(height: 16),
                                      SocialAuthSection(
                                        showDivider: false,
                                        compact: _pageState == PageState.login,
                                        cleanPills: true,
                                      ),
                                      const SizedBox(height: 20),
                                      _AuthSwitchPrompt(
                                        pageState: _pageState,
                                        enabled: !loading,
                                        onSelected: _selectPage,
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: RiksaMotion.resolve(
                              context,
                              const Duration(milliseconds: 180),
                            ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _BuddyFeedback { none, validation, error, success }

class _AuthBuddyStrip extends StatelessWidget {
  const _AuthBuddyStrip({
    required this.species,
    required this.controller,
    required this.line,
  });

  final MascotSpecies species;
  final MascotController controller;
  final String line;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final height = keyboardOpen
        ? 0.0
        : (media.size.height * .18).clamp(112.0, 154.0);
    final buddySize = height / MascotView.heightFactor;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35);
    return AnimatedContainer(
      duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
      curve: RiksaMotion.standardCurve,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MascotView(
                      species: species,
                      size: buddySize,
                      controller: controller,
                      interactive: true,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: buddySize * .4),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: MascotSpeechBubble(
                            key: const Key('auth_buddy_bubble'),
                            line: line,
                            tail: SpeechTail.left,
                            maxWidth: 390,
                            textAlign: TextAlign.start,
                            style: style,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    rightDotColor: palette.reward,
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            side: BorderSide.none,
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
    required this.identifierFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.passwordShake,
    required this.loading,
    required this.error,
    required this.reasonCopy,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode identifierFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final int passwordShake;
  final bool loading;
  final String? error;
  final String? reasonCopy;
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
            subtitle: reasonCopy ?? strings.loginSubtitle,
          ),
          const SizedBox(height: 22),
          if (error != null) ...[
            AuthErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('login_username'),
            controller: identifierController,
            focusNode: identifierFocus,
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
          _PasswordShake(
            generation: passwordShake,
            child: TextFormField(
              key: const Key('login_password'),
              controller: passwordController,
              focusNode: passwordFocus,
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
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('forgot_password'),
              onPressed: loading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                side: BorderSide.none,
              ),
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
    required this.usernameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.confirmationFocus,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.passwordShake,
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
  final FocusNode usernameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmationFocus;
  final bool obscurePassword;
  final bool obscureConfirmation;
  final int passwordShake;
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
            focusNode: usernameFocus,
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
            focusNode: emailFocus,
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
          _PasswordShake(
            generation: passwordShake,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('register_password'),
                  controller: passwordController,
                  focusNode: passwordFocus,
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
                  focusNode: confirmationFocus,
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
              ],
            ),
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

class _PasswordShake extends StatelessWidget {
  const _PasswordShake({required this.generation, required this.child});

  final int generation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (generation == 0 || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(generation),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, progress, child) => Transform.translate(
        offset: Offset(
          7 * (1 - progress) * math.sin(progress * math.pi * 6),
          0,
        ),
        child: child,
      ),
      child: child,
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
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton(
      key: buttonKey,
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? palette.brand : palette.brandStrong,
        foregroundColor: palette.onBrand,
        disabledBackgroundColor: palette.outline,
        disabledForegroundColor: palette.inkFaint,
        shadowColor: Colors.transparent,
        elevation: 0,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(52),
      ),
      child: AnimatedSwitcher(
        duration: RiksaMotion.resolve(
          context,
          const Duration(milliseconds: 160),
        ),
        child: Text(
          label,
          key: const ValueKey('label'),
          style: RiksaTypography.bodyStyleFor(
            label,
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
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
