import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_brand.dart';
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

  /// Fetching the transcript of an existing chat. Until it arrives the screen
  /// must not look like a brand-new conversation, and nothing can be sent.
  bool _historyLoading = false;
  bool _historyFailed = false;

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
    if (_sessionId != null) {
      _historyLoading = true;
      _load();
    }
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
    final sessionId = _sessionId!;
    setState(() {
      _historyLoading = true;
      _historyFailed = false;
    });
    try {
      final chat = await ref.read(aiChatApiProvider).session(sessionId);
      if (!mounted || _sessionId != sessionId) return;
      setState(() {
        // Keep any turn added meanwhile instead of letting the older
        // transcript overwrite it.
        final known = {for (final m in chat.messages) m.id};
        _entries = [
          for (final m in chat.messages) _ChatEntry(m),
          ..._entries.where((entry) => !known.contains(entry.message.id)),
        ];
        _historyLoading = false;
      });
      _scrollToEnd();
    } catch (_) {
      if (!mounted || _sessionId != sessionId) return;
      setState(() {
        _historyLoading = false;
        _historyFailed = true;
      });
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
    if (text.isEmpty || _loading || _historyLoading || _historyFailed) return;
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
                ? AppLocalizations.of(context)!.aiLoginRequired
                : AppLocalizations.of(context)!.aiReplyFailed,
          ),
          action: isAuth
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.login,
                  onPressed: _requestLogin,
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

  void _requestLogin() {
    final current = GoRouterState.of(context).uri.toString();
    context.push(
      Uri(path: '/auth/login', queryParameters: {'from': current}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = widget.lessonTitle?.trim();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  RiksaBackButton(
                    key: const ValueKey('ai-chat-back'),
                    fallbackLocation: '/ai',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  RiksaDoodle(
                    RiksaDoodleKind.sparkle,
                    size: 16,
                    color: context.riksa.learningStrong,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.aiCoachTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.titleStyleFor(
                        l10n.aiCoachTitle,
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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
              )
            else if (widget.learningContext != null &&
                widget.learningContext!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.md,
                  0,
                  RiksaSpacing.md,
                  RiksaSpacing.xs,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AiContextChip(
                    label: widget.learningContext!
                        .split('\n')
                        .first
                        .split('.')
                        .first
                        .trim(),
                  ),
                ),
              ),
            Expanded(
              child: _historyFailed
                  ? RiksaStateView(
                      key: const ValueKey('ai-chat-history-error'),
                      icon: Icons.cloud_off_rounded,
                      title: l10n.aiChatLoadFailed,
                      body: l10n.aiChatLoadFailedBody,
                      actionLabel: l10n.tryAgain,
                      onAction: _load,
                    )
                  : _historyLoading
                  ? const _TranscriptSkeleton()
                  : _entries.isEmpty && !_loading
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
            if (_historyFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
                child: TextButton.icon(
                  key: const ValueKey('ai-chat-history-back'),
                  onPressed: () => RiksaBackButton.navigateBack(
                    context,
                    fallbackLocation: '/ai',
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(l10n.back),
                ),
              )
            else ...[
              if (_entries.isNotEmpty && !_loading && !_historyLoading)
                _QuickPromptsBar(onSelected: _useStarter),
              _Composer(
                controller: _controller,
                focusNode: _focus,
                enabled: _canSend && !_loading && !_historyLoading,
                onSend: _send,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder bubbles shown while an existing chat's transcript loads.
class _TranscriptSkeleton extends StatelessWidget {
  const _TranscriptSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      Widget bubble(double fraction, {required bool user}) => Align(
        alignment: user
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: RiksaSkeleton(
          width: width * fraction,
          height: user ? 44 : 72,
          radius: AppRadii.large,
        ),
      );
      return Semantics(
        key: const ValueKey('ai-chat-history-loading'),
        label: AppLocalizations.of(context)!.loading,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(RiksaSpacing.md),
          children: [
            bubble(.55, user: true),
            const SizedBox(height: RiksaSpacing.sm),
            bubble(.8, user: false),
            const SizedBox(height: RiksaSpacing.sm),
            bubble(.45, user: true),
            const SizedBox(height: RiksaSpacing.sm),
            bubble(.75, user: false),
          ],
        ),
      );
    },
  );
}

/// First screen of a new conversation: the coach says hello, then offers
/// a few ways in.
class _Opener extends StatelessWidget {
  const _Opener({required this.onSelected, this.lesson});

  final ValueChanged<String> onSelected;
  final String? lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final greeting = lesson == null || lesson!.isEmpty
        ? l10n.aiCoachGreeting
        : '${l10n.aiLessonContext(lesson!)}\n${l10n.aiChatOpener}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.learningSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const RiksaMascot(size: 54, showSparkles: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  key: const ValueKey('ai-coach-greeting'),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(AppRadii.large),
                      bottomLeft: Radius.circular(AppRadii.large),
                      bottomRight: Radius.circular(AppRadii.large),
                    ),
                    border: Border.all(color: palette.outline),
                    boxShadow: RiksaElevation.low(theme.brightness),
                  ),
                  child: Text(
                    greeting,
                    style: RiksaTypography.bodyStyleFor(
                      greeting,
                      theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.aiTryAskingAbout,
            style: RiksaTypography.bodyStyleFor(
              l10n.aiTryAskingAbout,
              theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 12),
          AiStarterPrompts(onSelected: onSelected, vertical: true),
        ],
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
    final palette = context.riksa;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = context.riksaGlass;
    final sendOuterFill = isDark ? glass.selectedFill : glass.fill;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 5, 4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadii.panelBorder,
          border: Border.all(color: palette.outline),
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
                  hintStyle: TextStyle(color: palette.inkFaint),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            RiksaTapFeedback(
              enabled: enabled,
              child: SizedBox.square(
                dimension: 50,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: sendOuterFill,
                    shape: CircleBorder(side: BorderSide(color: glass.border)),
                    shadows: RiksaElevation.overlay(theme.brightness),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: glass.blurSigma,
                        sigmaY: glass.blurSigma,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: glass.selectedFill,
                            shape: CircleBorder(
                              side: BorderSide(color: glass.selectedBorder),
                            ),
                            shadows: RiksaElevation.raised(theme.brightness),
                          ),
                          child: IconButton(
                            key: const ValueKey('send-ai-message'),
                            tooltip: l10n.aiSendMessage,
                            onPressed: enabled ? onSend : null,
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: palette.brand,
                              disabledForegroundColor: palette.inkMuted,
                              minimumSize: const Size.square(42),
                              shape: const CircleBorder(),
                            ),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPromptsBar extends StatelessWidget {
  const _QuickPromptsBar({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final prompts = isKhmer
        ? const [
            'ពន្យល់សង្ខេបចំណុចសំខាន់ៗ',
            'សុំលំហាត់សាកល្បងមួយ',
            'ពន្យល់ឲ្យកាន់តែងាយយល់',
            'រូបមន្តសំខាន់ៗ',
          ]
        : const [
            'Summarize key points',
            'Give a practice question',
            'Explain in simpler terms',
            'Key formulas',
          ];

    return Container(
      key: const ValueKey('ai-quick-followup-chips'),
      height: 38,
      margin: const EdgeInsets.only(bottom: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: RiksaSpacing.xs),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return RiksaTapFeedback(
            child: ActionChip(
              key: ValueKey('ai-quick-chip-$prompt'),
              avatar: Icon(
                Icons.auto_awesome,
                size: 13,
                color: context.riksa.learningStrong,
              ),
              label: Text(
                prompt,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              onPressed: () => onSelected(prompt),
            ),
          );
        },
      ),
    );
  }
}
