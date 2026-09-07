import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';
import 'widgets/ai_chat_ui.dart';
import 'widgets/ai_tutor_ui.dart';

/// One message in the transcript, plus whether it ever reached the server.
class _ChatEntry {
  const _ChatEntry(this.message, {this.failed = false});
  final AiChatMessage message;
  final bool failed;
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({
    super.key,
    this.sessionId,
    this.lessonTitle,
    this.learningContext,
    this.initialPrompt,
  });

  final String? sessionId;

  /// Lesson the tutor was opened from, shown to the student and sent to the
  /// model so the answer is grounded in what they are actually reading.
  final String? lessonTitle;
  final String? learningContext;
  final String? initialPrompt;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  var _entries = <_ChatEntry>[];
  String? _sessionId;
  bool _loading = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    _controller.addListener(_syncCanSend);
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      _controller.text = prompt;
      _controller.selection = TextSelection.collapsed(offset: prompt.length);
    }
    if (_sessionId != null) _load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncCanSend)
      ..dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncCanSend() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) setState(() => _canSend = canSend);
  }

  Future<void> _load() async {
    try {
      final chat = await ref.read(aiChatApiProvider).session(_sessionId!);
      if (!mounted) return;
      setState(() => _entries = [for (final m in chat.messages) _ChatEntry(m)]);
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.aiChatLoadFailed)),
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: RiksaMotion.resolve(context, RiksaMotion.standard),
        curve: RiksaMotion.standardCurve,
      );
    });
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;
    if (retryText == null) _controller.clear();
    setState(() {
      _loading = true;
      _entries = [
        ..._entries.where((entry) => !entry.failed),
        _ChatEntry(
          AiChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            role: 'user',
            content: text,
          ),
        ),
      ];
    });
    _scrollToEnd();
    try {
      final turn = await ref
          .read(aiChatApiProvider)
          .send(
            sessionId: _sessionId,
            message: text,
            learningContext: _contextPayload(),
          );
      if (!mounted) return;
      setState(() {
        _sessionId = turn.sessionId;
        _entries = [..._entries, _ChatEntry(turn.message)];
      });
      ref.invalidate(aiChatSessionsProvider);
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      // Keep the message on screen and marked, instead of losing what they
      // typed to a failed request.
      setState(() {
        if (_entries.isNotEmpty) {
          final last = _entries.last;
          _entries = [
            ..._entries.take(_entries.length - 1),
            _ChatEntry(last.message, failed: true),
          ];
        }
      });
      final isAuth = e is DioException && e.response?.statusCode == 401;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAuth
                ? 'Please log in to chat with the AI Tutor.'
                : AppLocalizations.of(context)!.aiReplyFailed,
          ),
          action: isAuth
              ? SnackBarAction(
                  label: 'Log in',
                  onPressed: () => context.push('/auth/login'),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _contextPayload() {
    final lesson = widget.lessonTitle?.trim();
    final extra = widget.learningContext?.trim();
    final parts = [
      if (lesson != null && lesson.isNotEmpty) 'Lesson: $lesson',
      if (extra != null && extra.isNotEmpty) extra,
    ];
    return parts.isEmpty ? null : parts.join('. ');
  }

  void _useStarter(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.collapsed(offset: prompt.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = widget.lessonTitle?.trim();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            RiksaPageHeader(
              title: l10n.aiTutor,
              leading: RiksaRoundedIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: context.pop,
              ),
            ),
            if (lesson != null && lesson.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.md,
                  0,
                  RiksaSpacing.md,
                  RiksaSpacing.xs,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AiContextChip(label: l10n.aiLessonContext(lesson)),
                ),
              ),
            Expanded(
              child: _entries.isEmpty && !_loading
                  ? _Opener(lesson: lesson, onSelected: _useStarter)
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        RiksaSpacing.md,
                        RiksaSpacing.xs,
                        RiksaSpacing.md,
                        RiksaSpacing.md,
                      ),
                      itemCount: _entries.length + (_loading ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: RiksaSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == _entries.length) {
                          return const AiThinkingBubble();
                        }
                        final entry = _entries[index];
                        return KeyedSubtree(
                          key: ValueKey('ai-message-${entry.message.id}'),
                          child: entry.message.isUser
                              ? AiUserBubble(
                                  content: entry.message.content,
                                  failed: entry.failed,
                                  onRetry: entry.failed
                                      ? () => _send(entry.message.content)
                                      : null,
                                )
                              : AiTutorBubble(content: entry.message.content),
                        );
                      },
                    ),
            ),
            _Composer(
              controller: _controller,
              focusNode: _focus,
              enabled: _canSend && !_loading,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// First screen of a new conversation: one question, and three ways in.
class _Opener extends StatelessWidget {
  const _Opener({required this.onSelected, this.lesson});

  final ValueChanged<String> onSelected;
  final String? lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RiksaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 28, color: context.riksa.jade),
            const SizedBox(height: RiksaSpacing.sm),
            Text(
              lesson == null || lesson!.isEmpty
                  ? l10n.aiChatOpener
                  : l10n.aiLessonContext(lesson!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: RiksaSpacing.md),
            AiStarterPrompts(onSelected: onSelected),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RiksaSpacing.sm,
        RiksaSpacing.xs,
        RiksaSpacing.sm,
        RiksaSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('ai-message-input'),
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l10n.aiComposerHint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.md,
                  vertical: RiksaSpacing.sm,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.panelBorder,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadii.panelBorder,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.panelBorder,
                  borderSide: BorderSide(color: context.riksa.jade, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: RiksaSpacing.xs),
          IconButton.filled(
            key: const ValueKey('send-ai-message'),
            tooltip: l10n.aiSendMessage,
            onPressed: enabled ? onSend : null,
            iconSize: 22,
            style: IconButton.styleFrom(minimumSize: const Size.square(48)),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
