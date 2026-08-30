import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/ai_chat_provider.dart';

class AiTutorScreen extends ConsumerWidget {
  const AiTutorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chats = ref.watch(aiChatSessionsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RiksaPageHeader(
              title: l10n.aiTutor,
              subtitle: 'Your patient learning coach',
              trailing: RiksaRoundedIconButton(
                key: const ValueKey('new-ai-chat'),
                icon: Icons.add_comment_rounded,
                tooltip: 'New chat',
                onPressed: () => context.push('/ai/chat/new'),
              ),
            ),
          ),
          chats.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverFillRemaining(
              child: IllustratedEmptyState(
                title: 'Tutor unavailable',
                body: 'Check the server connection and try again.',
                actionLabel: l10n.tryAgain,
                onAction: () => ref.invalidate(aiChatSessionsProvider),
              ),
            ),
            data: (items) => items.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: IllustratedEmptyState(
                      title: 'Ask anything you are learning',
                      body:
                          'Start a private learning conversation in Khmer or English.',
                      actionLabel: 'Start a chat',
                      onAction: () => context.push('/ai/chat/new'),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = items[index];
                        return RiksaPastelCard(
                          key: ValueKey('ai-chat-${chat.id}'),
                          onTap: () => context.push('/ai/chat/${chat.id}'),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: context.riksa.jade,
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  chat.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await ref
                                        .read(aiChatApiProvider)
                                        .delete(chat.id);
                                    ref.invalidate(aiChatSessionsProvider);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete chat'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
