import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

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
  String? _error;
  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(authApiProvider);
      if (_step == 0) {
        if (_identifier.text.trim().isEmpty) {
          throw const FormatException(
            'Enter your username, email, or Telegram ID.',
          );
        }
        await api.forgotPassword(_identifier.text.trim());
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        if (_code.text.trim().length != 6) {
          throw const FormatException('Enter the 6-digit code.');
        }
        setState(() => _step = 2);
      } else {
        if (_password.text.length < 8) {
          throw const FormatException('Use at least 8 characters.');
        }
        if (_password.text != _confirm.text) {
          throw const FormatException('Passwords do not match.');
        }
        await api.resetPassword(
          identifier: _identifier.text.trim(),
          code: _code.text.trim(),
          newPassword: _password.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset. You can sign in now.'),
            ),
          );
          context.go('/auth/login');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : error.toString().replaceFirst('AuthFailure: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final titles = [
      'Recover your account',
      'Enter verification code',
      'Choose a new password',
    ];
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(titles[_step])),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Step ${_step + 1} of 3',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 20),
            if (_step == 0)
              TextField(
                key: const ValueKey('recovery-identifier'),
                controller: _identifier,
                decoration: const InputDecoration(
                  labelText: 'Username, email, or Telegram ID',
                ),
              ),
            if (_step == 1)
              TextField(
                key: const ValueKey('recovery-code'),
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '6-digit code'),
              ),
            if (_step == 2) ...[
              TextField(
                key: const ValueKey('recovery-password'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _continue,
              child: Text(
                _loading
                    ? 'Please wait…'
                    : _step == 2
                    ? 'Reset password'
                    : 'Continue',
              ),
            ),
            if (_step == 1)
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await ref
                            .read(authApiProvider)
                            .forgotPassword(_identifier.text.trim());
                      },
                child: const Text('Resend code'),
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
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
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
                    success ? 'Email verified' : 'Verification failed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    success
                        ? 'Your Riksa account email is now verified.'
                        : 'This verification link is invalid or expired.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Continue'),
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
