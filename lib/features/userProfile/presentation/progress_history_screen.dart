import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/riksa_components.dart';
import '../providers/profile_provider.dart';

class ProgressHistoryScreen extends ConsumerWidget {
  const ProgressHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Progress history'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'XP activity'),
            Tab(text: 'Rank changes'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _XpHistory(ref: ref),
          _RankHistory(ref: ref),
        ],
      ),
    ),
  );
}

class _XpHistory extends StatelessWidget {
  const _XpHistory({required this.ref});
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) => ref
      .watch(profileDashboardProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load XP history.')),
        data: (data) => data.activities.isEmpty
            ? const IllustratedEmptyState(
                title: 'No XP yet',
                body: 'Complete a lesson to start your history.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: data.activities.length,
                itemBuilder: (context, i) {
                  final item = data.activities[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.bolt_rounded),
                    ),
                    title: Text(item.sourceType.replaceAll('_', ' ')),
                    subtitle: Text(
                      item.createdAt == null
                          ? ''
                          : DateFormat.yMMMd().add_jm().format(
                              item.createdAt!.toLocal(),
                            ),
                    ),
                    trailing: Text('+${item.amount} XP'),
                  );
                },
              ),
      );
}

class _RankHistory extends StatelessWidget {
  const _RankHistory({required this.ref});
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) => ref
      .watch(rankHistoryProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load rank history.')),
        data: (items) => items.isEmpty
            ? const IllustratedEmptyState(
                title: 'No rank changes yet',
                body: 'Keep earning XP to move up the leaderboard.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final improved = item.newRank < item.oldRank;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        improved ? Icons.trending_up : Icons.trending_down,
                      ),
                    ),
                    title: Text('${item.scope} rank'),
                    subtitle: Text(
                      item.changedAt == null
                          ? ''
                          : DateFormat.yMMMd().format(
                              item.changedAt!.toLocal(),
                            ),
                    ),
                    trailing: Text('#${item.oldRank} → #${item.newRank}'),
                  );
                },
              ),
      );
}
