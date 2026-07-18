import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/riksa_logo.dart';
import '../../../core/widgets/telegram_logo.dart';
import '../data/auth_models.dart';
import '../providers/auth_provider.dart';

/// Telegram OTP flow: enter chat ID → send code → enter code → verify.
class TelegramOtpScreen extends ConsumerStatefulWidget {
  const TelegramOtpScreen({super.key});

  @override
  ConsumerState<TelegramOtpScreen> createState() => _TelegramOtpScreenState();
}

enum _OtpStep { identifier, code }

class _TelegramOtpScreenState extends ConsumerState<TelegramOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  _OtpStep _step = _OtpStep.identifier;
  bool _sending = false;
  bool _verifying = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final api = ref.read(authApiProvider);
      final result = await api.sendOtp(
        OtpSendRequest(identifier: _identifierCtrl.text.trim()),
      );
      if (!mounted) return;
      if (result.success) {
        setState(() => _step = _OtpStep.code);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code sent to your Telegram')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to send OTP code'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send OTP code'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    try {
      final api = ref.read(authApiProvider);
      final result = await api.verifyOtp(
        OtpVerifyRequest(
          identifier: _identifierCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      if (result.success) {
        // OTP verified. Backend doesn't return an AuthResponse here —
        // the user needs to set a password or use another login method.
        // For now, show a success message and go back to login.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram verified! Please log in.')),
        );
        context.go('/auth/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Invalid or expired code'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid or expired code'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const RiksaLogo(fontSize: 28),
                  const LanguageToggle(),
                ],
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (_step == _OtpStep.code) {
                      setState(() => _step = _OtpStep.identifier);
                    } else {
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                ),
              ),

              // Telegram icon
              const Center(child: TelegramLogo(size: 56)),
              const SizedBox(height: 20),

              Text(
                _step == _OtpStep.identifier ? 'Continue with Telegram' : 'Enter the code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == _OtpStep.identifier
                    ? 'Start our bot and paste your chat ID'
                    : 'We sent a code to your Telegram. Enter it below.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8A8A8A),
                    ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == _OtpStep.identifier) ...[
                      TextFormField(
                        controller: _identifierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telegram Chat ID',
                          hintText: 'Start our bot and paste your chat ID',
                          prefixIcon: Icon(Icons.send_outlined, color: Color(0xFF8A8A8A)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'This field is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _sending ? null : _sendCode,
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Send Code'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'OTP Code',
                          hintText: '6-digit code',
                          prefixIcon: Icon(Icons.password_outlined, color: Color(0xFF8A8A8A)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'This field is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _verifying ? null : _verifyCode,
                        child: _verifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Verify'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _sending ? null : _sendCode,
                        child: const Text('Resend code'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}