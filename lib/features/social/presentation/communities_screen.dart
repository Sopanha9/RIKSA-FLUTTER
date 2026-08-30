import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/riksa_components.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});
  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  List<SocialCategory>? _items;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ref.read(socialApiProvider).categories();
      if (mounted) {
        setState(() {
          _items = value;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load communities.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Communities')),
    body: _items == null
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : IllustratedEmptyState(
                    title: 'Communities unavailable',
                    body: _error!,
                    actionLabel: 'Try again',
                    onAction: _load,
                  ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _items!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = _items![i];
              return RiksaPastelCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${item.memberCount} members${item.description == null ? '' : ' • ${item.description}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        final updated = await ref
                            .read(socialApiProvider)
                            .setCategoryJoined(item.id, joined: !item.joined);
                        if (mounted) setState(() => _items![i] = updated);
                      },
                      child: Text(item.joined ? 'Joined' : 'Join'),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}
