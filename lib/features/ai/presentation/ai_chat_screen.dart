import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.sessionId});
  final String? sessionId;
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  var _messages = <AiChatMessage>[];
  String? _sessionId;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    if (_sessionId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final chat = await ref.read(aiChatApiProvider).session(_sessionId!);
      if (mounted) setState(() => _messages = chat.messages);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load this chat.')),
        );
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _loading = true;
      _messages.add(
        AiChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          content: text,
        ),
      );
    });
    try {
      final turn = await ref
          .read(aiChatApiProvider)
          .send(sessionId: _sessionId, message: text);
      if (!mounted) return;
      setState(() {
        _sessionId = turn.sessionId;
        _messages.add(turn.message);
      });
      ref.invalidate(aiChatSessionsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The tutor could not answer. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AI Tutor'),
      leading: BackButton(onPressed: () => context.pop()),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'What would you like to understand today?',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          key: ValueKey('ai-message-${message.id}'),
                          constraints: const BoxConstraints(maxWidth: 620),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? context.riksa.jade
                                : context.riksa.surfaceRaised,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: message.isUser
                              ? Text(
                                  message.content,
                                  style: const TextStyle(color: Colors.white),
                                )
                              : MarkdownBody(data: message.content),
                        ),
                      );
                    },
                  ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('ai-message-input'),
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ask your tutor…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const ValueKey('send-ai-message'),
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
