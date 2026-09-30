import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/presentation/widgets/code_buddy.dart';
import '../data/auth_api.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// The rule the server enforces on new passwords, checked as the learner types
/// so they never have to learn it from an error.
class PasswordRules {
  const PasswordRules(this.password, this.confirm);

  final String password;
  final String confirm;

  bool get longEnough => password.length >= 8;
  bool get hasUpper => password.contains(RegExp('[A-Z]'));
  bool get hasLower => password.contains(RegExp('[a-z]'));
  bool get hasDigit => password.contains(RegExp('[0-9]'));
  bool get matches => password.isNotEmpty && password == confirm;
  bool get strongEnough => longEnough && hasUpper && hasLower && hasDigit;
}

/// Something the learner typed that the screen itself can catch, kept as a
/// code so the wording is chosen in their language at display time.
enum RecoveryIssue { missingIdentifier, codeLength, weakPassword, mismatch }

class RecoveryValidationException implements Exception {
  const RecoveryValidationException(this.issue);
  final RecoveryIssue issue;
}

/// Turns what went wrong into something a learner can act on, in their own
/// language. Server text is never shown raw: it can carry field names and
/// status codes, and it is always English.
String friendlyRecoveryError(
  Object error, {
  required int step,
  required AppLocalizations l10n,
}) {
  if (error is RecoveryValidationException) {
    return switch (error.issue) {
      RecoveryIssue.missingIdentifier => l10n.recoveryNeedIdentifier,
      RecoveryIssue.codeLength => l10n.recoveryCodeLength,
      RecoveryIssue.weakPassword => l10n.recoveryChecklistIncomplete,
      RecoveryIssue.mismatch => l10n.recoveryPasswordsDiffer,
    };
  }
  if (error is AuthFailure) {
    final text = error.message.toLowerCase();
    switch (error.kind) {
      case AuthFailureKind.network:
        return l10n.recoveryErrorNetwork;
      case AuthFailureKind.rateLimited:
        return l10n.recoveryErrorRateLimited;
      case AuthFailureKind.server:
        return l10n.recoveryErrorServer;
      case AuthFailureKind.validation ||
          AuthFailureKind.unauthorized ||
          AuthFailureKind.forbidden:
        if (text.contains('password')) return l10n.recoveryErrorPassword;
        if (text.contains('code') || text.contains('expired')) {
          return l10n.recoveryErrorCode;
        }
        if (step == 0) return l10n.recoveryErrorAccount;
        return l10n.recoveryErrorDetails;
    }
  }
  return l10n.recoveryErrorGeneric;
}

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key});
  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The checklist and button follow what the learner types.
    for (final controller in [_password, _confirm]) {
      controller.addListener(() => setState(() {}));
    }
  }

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(authApiProvider);
      if (_step == 0) {
        if (_identifier.text.trim().isEmpty) {
          throw const RecoveryValidationException(
            RecoveryIssue.missingIdentifier,
          );
        }
        await api.forgotPassword(_identifier.text.trim());
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        if (_code.text.trim().length != 6) {
          throw const RecoveryValidationException(RecoveryIssue.codeLength);
        }
        setState(() => _step = 2);
      } else {
        final rules = PasswordRules(_password.text, _confirm.text);
        if (!rules.strongEnough) {
          throw const RecoveryValidationException(RecoveryIssue.weakPassword);
        }
        if (!rules.matches) {
          throw const RecoveryValidationException(RecoveryIssue.mismatch);
        }
        await api.resetPassword(
          identifier: _identifier.text.trim(),
          code: _code.text.trim(),
          newPassword: _password.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.recoveryPasswordSaved,
              ),
            ),
          );
          context.go('/auth/login');
        }
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(
          () => _error = friendlyRecoveryError(error, step: _step, l10n: l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    final (title, subtitle) = switch (_step) {
      0 => (
        l10n.recoveryStepIdentifierTitle,
        l10n.recoveryStepIdentifierSubtitle,
      ),
      1 => (l10n.recoveryStepCodeTitle, l10n.recoveryStepCodeSubtitle),
      _ => (l10n.recoveryStepPasswordTitle, l10n.recoveryStepPasswordSubtitle),
    };
    final rules = PasswordRules(_password.text, _confirm.text);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthScaffold(
        onBack: _back,
        child: AuthPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 1)
                CodeBuddy(
                  key: const ValueKey('recovery-code-buddy'),
                  controller: _code,
                  length: 6,
                  hasError: _error != null,
                  startLine: l10n.codeBuddyCheckInbox,
                )
              else
                _RecoveryIllustration(step: _step),
              const SizedBox(height: 20),
              _StepProgress(step: _step),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                child: AuthHeader(
                  key: ValueKey('recovery-header-$_step'),
                  title: title,
                  subtitle: subtitle,
                ),
              ),
              const SizedBox(height: 22),
              if (_step == 0)
                TextField(
                  key: const ValueKey('recovery-identifier'),
                  controller: _identifier,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _continue(),
                  decoration: InputDecoration(
                    labelText: l10n.recoveryIdentifierLabel,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
              if (_step == 1)
                OtpCodeField(
                  fieldKey: const ValueKey('recovery-code'),
                  controller: _code,
                  length: 6,
                  autofocus: true,
                  enabled: !_loading,
                  hasError: _error != null,
                  semanticLabel: l10n.recoveryStepCodeTitle,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  // Like most apps: a full code moves on by itself.
                  onCompleted: (_) {
                    if (!_loading) _continue();
                  },
                ),
              if (_step == 2) ...[
                TextField(
                  key: const ValueKey('recovery-password'),
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.recoveryNewPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('recovery-confirm'),
                  controller: _confirm,
                  obscureText: _obscure,
                  onSubmitted: (_) => _loading ? null : _continue(),
                  decoration: InputDecoration(
                    labelText: l10n.recoveryConfirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _PasswordChecklist(rules: rules),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                _FriendlyNotice(message: _error!),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const ValueKey('recovery-continue'),
                onPressed: _loading ? null : _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _loading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: palette.brand,
                        ),
                      )
                    : Text(switch (_step) {
                        0 => l10n.recoverySendCode,
                        1 => l10n.recoveryVerifyCode,
                        _ => l10n.recoverySavePassword,
                      }),
              ),
              if (_step == 1) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(authApiProvider)
                                .forgotPassword(_identifier.text.trim());
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.recoveryResendSent)),
                            );
                          } catch (error) {
                            if (mounted) {
                              setState(
                                () => _error = friendlyRecoveryError(
                                  error,
                                  step: _step,
                                  l10n: l10n,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(l10n.recoveryResend),
                ),
              ],
              if (_step == 0) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: Text(l10n.recoveryBackToSignIn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft badge that changes with each step: someone to help, a message on
/// its way, then a key for the new lock. Drawn in code so it follows the
/// theme and costs no asset.
class _RecoveryIllustration extends StatelessWidget {
  const _RecoveryIllustration({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final icon = switch (step) {
      0 => Icons.support_agent_rounded,
      1 => Icons.mark_email_unread_rounded,
      _ => Icons.key_rounded,
    };
    return Semantics(
      image: true,
      label: AppLocalizations.of(context)!.recoveryIllustrationLabel(step + 1),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer halo and inner disc.
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.brandSoft.withValues(alpha: .55),
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.brandSoft,
                ),
              ),
              // Floating bits around the badge.
              const Positioned(
                left: 0,
                right: 0,
                top: 6,
                child: Align(
                  alignment: Alignment(-.42, 0),
                  child: _Dot(size: 12, lime: true),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Align(
                  alignment: Alignment(.46, 0),
                  child: _Dot(size: 9, lime: false),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 20,
                child: Align(
                  alignment: const Alignment(.4, 0),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: palette.brand.withValues(alpha: .7),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
                switchInCurve: RiksaMotion.emphasisCurve,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Container(
                  key: ValueKey(step),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.brand,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: .3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.lime});

  final double size;
  final bool lime;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: lime
          ? context.riksa.reward
          : context.riksa.brand.withValues(alpha: .45),
    ),
  );
}

/// Three segments that fill as the learner moves through recovery.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Semantics(
      label: AppLocalizations.of(context)!.recoveryStepProgress(step + 1, 3),
      child: Row(
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.fullBorder,
                  color: index <= step ? palette.brand : palette.brandSoft,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Text(
              '${step + 1}/3',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live checklist for the new password.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.rules});

  final PasswordRules rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (l10n.passwordRuleLength, rules.longEnough),
      (l10n.passwordRuleUppercase, rules.hasUpper),
      (l10n.passwordRuleLowercase, rules.hasLower),
      (l10n.passwordRuleDigit, rules.hasDigit),
      (l10n.passwordRuleMatch, rules.matches),
    ];
    return Container(
      key: const ValueKey('recovery-password-checklist'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: context.riksa.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, done) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _ChecklistRow(label: label, done: done),
            ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final doneColor = palette.jade;
    return Semantics(
      label: done
          ? AppLocalizations.of(context)!.checklistItemDone(label)
          : AppLocalizations.of(context)!.checklistItemPending(label),
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.fast),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? doneColor : Colors.transparent,
              border: Border.all(
                color: done ? doneColor : palette.outline,
                width: 1.6,
              ),
            ),
            child: done
                ? Icon(Icons.check_rounded, size: 14, color: palette.onJade)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: done ? palette.ink : palette.inkMuted,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A gentle note instead of a red alarm: warm amber, a lightbulb, plain words.
class _FriendlyNotice extends StatelessWidget {
  const _FriendlyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantic = context.riksa.semantic;
    final background = semantic.errorContainer;
    final ink = semantic.onErrorContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('recovery-error'),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.mediumBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 20, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, required this.token});
  final String token;
  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  late final Future<bool> _result;
  @override
  void initState() {
    super.initState();
    _result = widget.token.isEmpty
        ? Future.value(false)
        : ref.read(authApiProvider).verifyEmail(widget.token);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: FutureBuilder<bool>(
          future: _result,
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context)!;
            if (snapshot.connectionState != ConnectionState.done) {
              return Semantics(
                label: l10n.loading,
                child: const CircularProgressIndicator(),
              );
            }
            final success = snapshot.data == true;
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success
                        ? Icons.verified_rounded
                        : Icons.error_outline_rounded,
                    size: 88,
                    color: success ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    success
                        ? l10n.emailVerifiedTitle
                        : l10n.emailVerifyFailedTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    success
                        ? l10n.emailVerifiedBody
                        : l10n.emailVerifyFailedBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => context.go('/auth/login'),
                    child: Text(l10n.continueLabel),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
