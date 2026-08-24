import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/telegram_logo.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';
import '../data/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Passwordless Telegram flow: send OTP, verify it, then receive the same
/// Riksa token pair used by password and Google authentication.
class TelegramOtpScreen extends ConsumerStatefulWidget {
  const TelegramOtpScreen({super.key, this.isRegistration = false});

  final bool isRegistration;

  @override
  ConsumerState<TelegramOtpScreen> createState() => _TelegramOtpScreenState();
}

enum _OtpStep { account, code }

class _TelegramOtpScreenState extends ConsumerState<TelegramOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  _OtpStep _step = _OtpStep.account;
  bool _sending = false;
  String? _sendError;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool validateForm = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (validateForm && !_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    ref.read(authProvider.notifier).clearError();
    try {
      await ref
          .read(authApiProvider)
          .sendOtp(
            OtpSendRequest(identifier: _identifierController.text.trim()),
          );
      if (!mounted) return;
      setState(() => _step = _OtpStep.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.otpSendSuccess)),
      );
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _sendError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _sendError = AppLocalizations.of(context)!.otpSendFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .telegramSignIn(
          TelegramAuthRequest(
            identifier: _identifierController.text.trim(),
            code: _codeController.text.trim(),
            username: widget.isRegistration
                ? _usernameController.text.trim()
                : null,
            displayName: widget.isRegistration
                ? _displayNameController.text.trim()
                : null,
          ),
        );
  }

  void _back() {
    if (_step == _OtpStep.code) {
      ref.read(authProvider.notifier).clearError();
      setState(() {
        _step = _OtpStep.account;
        _codeController.clear();
      });
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final loading = auth is AuthLoading;
    final authError = auth is AuthError ? auth.message : null;
    final error = _sendError ?? authError;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated) context.go('/home');
    });

    return AuthScaffold(
      onBack: loading || _sending ? null : _back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: TelegramLogo(size: 58)),
          const SizedBox(height: 18),
          AuthHeader(
            eyebrow: strings.telegramEyebrow,
            title: _step == _OtpStep.code
                ? strings.enterTelegramCode
                : widget.isRegistration
                ? strings.telegramRegisterTitle
                : strings.telegramLoginTitle,
            subtitle: _step == _OtpStep.code
                ? strings.telegramOtpInstructions
                : widget.isRegistration
                ? strings.telegramRegisterSubtitle
                : strings.telegramLoginSubtitle,
          ),
          const SizedBox(height: 24),
          AuthPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    const SizedBox(height: 16),
                  ],
                  if (_step == _OtpStep.account) ...[
                    if (widget.isRegistration) ...[
                      TextFormField(
                        key: const Key('telegram_register_username'),
                        controller: _usernameController,
                        enabled: !_sending,
                        maxLength: 50,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: strings.username,
                          hintText: strings.usernameHint,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
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
                        key: const Key('telegram_register_display_name'),
                        controller: _displayNameController,
                        enabled: !_sending,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: strings.displayName,
                          hintText: strings.displayNameHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
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
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      key: const Key('telegram_identifier'),
                      controller: _identifierController,
                      enabled: !_sending,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _sendCode(),
                      decoration: InputDecoration(
                        labelText: strings.telegramChatId,
                        hintText: strings.telegramChatIdHint,
                        prefixIcon: const Icon(Icons.send_outlined),
                      ),
                      validator: (value) {
                        final chatId = value?.trim() ?? '';
                        if (chatId.isEmpty) return strings.requiredField;
                        if (!RegExp(r'^\d+$').hasMatch(chatId)) {
                          return strings.invalidTelegramChatId;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('telegram_send_code'),
                      onPressed: _sending ? null : _sendCode,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(strings.sendCode),
                    ),
                  ] else ...[
                    TextFormField(
                      key: const Key('telegram_otp_code'),
                      controller: _codeController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verifyCode(),
                      decoration: InputDecoration(
                        labelText: strings.otpCode,
                        hintText: strings.otpCodeHint,
                        prefixIcon: const Icon(Icons.password_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings.requiredField;
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                          return strings.invalidOtpCode;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('telegram_verify_code'),
                      onPressed: loading ? null : _verifyCode,
                      child: loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(strings.continueLabel),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading || _sending
                          ? null
                          : () => _sendCode(validateForm: false),
                      child: Text(strings.resendCode),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
