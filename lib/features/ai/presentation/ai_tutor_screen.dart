import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../data/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';
import 'widgets/ai_study_coach_hub.dart';
import 'widgets/ai_tutor_ui.dart';

/// Chats become searchable once the list is longer than a screenful.
const _searchThreshold = 6;

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  /// Chats removed from view while their undo window is open.
  final _pendingDeletion = <String>{};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(String id) => context.push('/ai/chat/$id');

  void _startChat({String? prompt, String? context}) {
    final params = <String, String>{};
    if (prompt != null && prompt.isNotEmpty) {
      params['prompt'] = prompt;
    }
    if (context != null && context.isNotEmpty) {
      params['context'] = context;
    }
    final uri = Uri(
      path: '/ai/chat/new',
      queryParameters: params.isEmpty ? null : params,
    );
    this.context.push(uri.toString());
  }

  Future<void> _refresh() async {
    ref.invalidate(aiChatSessionsProvider);
    await ref.read(aiChatSessionsProvider.future);
  }

  /// Deletes on the way out rather than on the tap, so a mistake costs one tap
  /// to undo instead of a whole conversation.
  Future<void> _deleteChat(AiChatSession chat) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(aiChatApiProvider);
    setState(() => _pendingDeletion.add(chat.id));
    final closed = await messenger
        .showSnackBar(
          SnackBar(
            content: Text(l10n.aiChatDeleted),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(label: l10n.aiUndo, onPressed: () {}),
          ),
        )
        .closed;
    if (closed == SnackBarClosedReason.action) {
      if (mounted) setState(() => _pendingDeletion.remove(chat.id));
      return;
    }
    try {
      await api.delete(chat.id);
      if (mounted) ref.invalidate(aiChatSessionsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingDeletion.remove(chat.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.aiChatDeleteFailed)));
    }
  }

  List<AiChatSession> _visible(List<AiChatSession> chats) {
    final l10n = AppLocalizations.of(context)!;
    final needle = _query.trim().toLowerCase();
    return chats.where((chat) {
      if (_pendingDeletion.contains(chat.id)) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${chat.displayTitle(l10n.aiChatFallbackTitle)} ${chat.previewText ?? ''}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chats = ref.watch(aiChatSessionsProvider);
    final total = chats.asData?.value.length ?? 0;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RiksaPageHeader(
                title: l10n.aiTutor,
                subtitle: l10n.aiTutorSubtitle,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.lg,
                  RiksaSpacing.sm,
                  RiksaSpacing.lg,
                  RiksaSpacing.xs,
                ),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('new-ai-chat'),
                    onPressed: _startChat,
                    icon: const Icon(Icons.auto_awesome, size: 19),
                    label: Text(l10n.aiAskNewQuestion),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: RiksaSpacing.md,
                  bottom: RiksaSpacing.sm,
                ),
                child: AiStudyCoachHub(
                  onTopicSelected: (topic) =>
                      _startChat(prompt: topic.prompt, context: topic.context),
                ),
              ),
            ),
            if (total >= _searchThreshold)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RiksaSpacing.lg,
                    RiksaSpacing.xs,
                    RiksaSpacing.lg,
                    0,
                  ),
                  child: RiksaSearchField(
                    key: const ValueKey('ai-chat-search'),
                    hintText: l10n.aiSearchChats,
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
            ...chats.when(
              loading: () => [const _ChatListSkeleton()],
              error: (_, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: IllustratedEmptyState(
                    title: l10n.aiTutorUnavailableTitle,
                    body: l10n.aiTutorUnavailableBody,
                    actionLabel: l10n.tryAgain,
                    onAction: () => ref.invalidate(aiChatSessionsProvider),
                  ),
                ),
              ],
              data: (items) => _content(_visible(items)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(List<AiChatSession> chats) {
    final l10n = AppLocalizations.of(context)!;
    if (chats.isEmpty && _query.trim().isNotEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(RiksaSpacing.xl),
            child: Center(
              child: Text(
                l10n.aiNoChatMatches,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.riksa.inkMuted),
              ),
            ),
          ),
        ),
      ];
    }
    if (chats.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: RiksaSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BuddyFaceReaction(
                    face: MascotFace.thinking,
                    size: 48,
                    loops: 1,
                  ),
                  const SizedBox(width: RiksaSpacing.sm),
                  Flexible(
                    child: Text(
                      l10n.aiBuddyHandoff,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.riksa.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RiksaSpacing.sm),
              IllustratedEmptyState(
                title: l10n.aiChatsEmptyTitle,
                body: l10n.aiChatsEmptyBody,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.lg,
                ),
                child: AiStarterPrompts(
                  onSelected: (prompt) => _startChat(prompt: prompt),
                ),
              ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ];
    }

    // A flat run of entries keeps the list lazy while still carrying the date
    // headers that break the column up.
    final entries = <Object>[];
    for (final section in groupAiChats(chats)) {
      entries
        ..add(section.group)
        ..addAll(section.chats);
    }
    final focalId = _query.trim().isEmpty
        ? entries.whereType<AiChatSession>().first.id
        : null;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          RiksaSpacing.lg,
          RiksaSpacing.xs,
          RiksaSpacing.lg,
          110,
        ),
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            if (entry is AiChatGroup) {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? RiksaSpacing.sm : RiksaSpacing.lg,
                  bottom: RiksaSpacing.xs,
                  left: RiksaSpacing.xxs,
                ),
                child: Text(
                  aiChatGroupLabel(l10n, entry).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.riksa.inkFaint,
                    letterSpacing: .8,
                  ),
                ),
              );
            }
            final chat = entry as AiChatSession;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: chat.id == focalId
                  ? AiFocalChatCard(
                      key: ValueKey('ai-chat-${chat.id}'),
                      chat: chat,
                      onTap: () => _openChat(chat.id),
                      onDelete: () => _deleteChat(chat),
                    )
                  : AiChatRow(
                      key: ValueKey('ai-chat-${chat.id}'),
                      chat: chat,
                      onTap: () => _openChat(chat.id),
                      onDelete: () => _deleteChat(chat),
                    ),
            );
          },
        ),
      ),
    ];
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) => const SliverPadding(
    padding: EdgeInsets.fromLTRB(
      RiksaSpacing.lg,
      RiksaSpacing.md,
      RiksaSpacing.lg,
      0,
    ),
    sliver: SliverList(
      delegate: SliverChildListDelegate.fixed([
        AiChatRowSkeleton(),
        SizedBox(height: 10),
        AiChatRowSkeleton(),
        SizedBox(height: 10),
        AiChatRowSkeleton(),
      ]),
    ),
  );
}
