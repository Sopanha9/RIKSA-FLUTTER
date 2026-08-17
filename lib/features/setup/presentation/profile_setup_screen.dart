import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_setup_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.step});
  final int step;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _searchController = TextEditingController();
  bool _showAllProvinces = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _continue(ProfileSetupState state) {
    if (widget.step == 1 && state.province != null) context.go('/setup/topics');
    if (widget.step == 2 && state.topics.isNotEmpty) context.go('/setup/goal');
    if (widget.step == 3 && state.learningGoal != null) {
      context.go('/identity/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(profileSetupProvider);
    return setup.when(
      loading: () => const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: _SetupColors.primary))),
      error: (_, __) => const Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Unable to load setup. Please try again.'))),
      data: (state) {
        if (widget.step == 1 && state.learningGoal != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/identity/intro');
          });
        }
        final enabled = switch (widget.step) { 1 => state.province != null, 2 => state.topics.isNotEmpty, _ => state.learningGoal != null };
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _SetupTopBar(step: widget.step),
                const SizedBox(height: 14),
                SetupProgressIndicator(activeStep: widget.step),
                const SizedBox(height: 28),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      key: ValueKey(widget.step),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: switch (widget.step) {
                        1 => _ProvinceStep(
                            selected: state.province,
                            searchController: _searchController,
                            showAll: _showAllProvinces,
                            onSearchChanged: (_) => setState(() {}),
                            onToggleAll: () => setState(() => _showAllProvinces = !_showAllProvinces),
                            onSelected: ref.read(profileSetupProvider.notifier).selectProvince,
                          ),
                        2 => _TopicsStep(selected: state.topics, onToggled: ref.read(profileSetupProvider.notifier).toggleTopic),
                        _ => _GoalStep(selected: state.learningGoal, onSelected: ref.read(profileSetupProvider.notifier).selectGoal),
                      },
                    ),
                  ),
                ),
                PrimarySetupButton(label: widget.step == 3 ? 'Get Started  →' : 'Continue', enabled: enabled, onPressed: () => _continue(state)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SetupTopBar extends StatelessWidget {
  const _SetupTopBar({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          IconButton(
            tooltip: 'Back',
            onPressed: step > 1 ? () => context.go(step == 2 ? '/setup/province' : '/setup/topics') : null,
            icon: Icon(Icons.arrow_back_rounded, color: step > 1 ? _SetupColors.text : _SetupColors.tertiaryText),
          ),
        ]),
      );
}

class SetupProgressIndicator extends StatelessWidget {
  const SetupProgressIndicator({super.key, required this.activeStep});
  final int activeStep;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38),
        child: Row(children: List.generate(5, (index) {
          if (index.isOdd) return Expanded(child: Container(height: 2, color: index ~/ 2 < activeStep - 1 ? _SetupColors.primary : _SetupColors.border));
          final step = index ~/ 2 + 1;
          final done = step < activeStep;
          final active = step == activeStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220), width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done || active ? _SetupColors.primary : _SetupColors.subtle, border: Border.all(color: done || active ? _SetupColors.primary : _SetupColors.strongBorder)),
            child: Center(child: done ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : Text('$step', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: active ? Colors.white : _SetupColors.secondaryText))),
          );
        })),
      );
}

class _ProvinceStep extends StatelessWidget {
  const _ProvinceStep({required this.selected, required this.searchController, required this.showAll, required this.onSearchChanged, required this.onToggleAll, required this.onSelected});
  final String? selected;
  final TextEditingController searchController;
  final bool showAll;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();
    final items = (showAll ? _provinces : _provinces.take(6)).where((province) => province.name.toLowerCase().contains(query)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SetupHeading(title: 'Select your province', description: 'Your province helps personalize your community and local leaderboard.'),
      const SizedBox(height: 20),
      TextField(controller: searchController, onChanged: onSearchChanged, decoration: InputDecoration(hintText: 'Search province...', prefixIcon: const Icon(Icons.search_rounded, color: _SetupColors.secondaryText), filled: true, fillColor: _SetupColors.subtle, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _SetupColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _SetupColors.border)))),
      const SizedBox(height: 20),
      const Text('Popular', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _SetupColors.text)),
      const SizedBox(height: 12),
      Expanded(child: items.isEmpty ? const Center(child: Text('No provinces found.', style: TextStyle(color: _SetupColors.secondaryText))) : GridView.builder(itemCount: items.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisExtent: 152, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (_, index) => ProvinceCard(province: items[index], selected: selected == items[index].name, onTap: () => onSelected(items[index].name)))),
      TextButton.icon(onPressed: onToggleAll, icon: Icon(showAll ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded), label: Text(showAll ? 'Show popular provinces' : 'View all provinces'), style: TextButton.styleFrom(foregroundColor: _SetupColors.primary)),
    ]);
  }
}

class _TopicsStep extends StatelessWidget {
  const _TopicsStep({required this.selected, required this.onToggled});
  final Set<String> selected;
  final ValueChanged<String> onToggled;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SetupHeading(title: 'Choose your topics', description: 'Pick a few topics and we’ll personalize what you see. You can change these anytime.'),
    const SizedBox(height: 22),
    Expanded(child: GridView.builder(itemCount: _topics.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisExtent: 104, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (_, index) { final topic = _topics[index]; return TopicCard(topic: topic, selected: selected.contains(topic.label), onTap: () => onToggled(topic.label)); })),
    const _InfoCard(),
  ]);
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.selected, required this.onSelected});
  final LearningGoal? selected;
  final ValueChanged<LearningGoal> onSelected;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SetupHeading(title: 'What brings you here?', description: 'This helps us personalize your experience from the start.'),
    const SizedBox(height: 18),
    Expanded(child: ListView.separated(itemCount: _goals.length, itemBuilder: (_, index) { final goal = _goals[index]; return LearningGoalCard(goal: goal, selected: selected == goal.value, onTap: () => onSelected(goal.value)); }, separatorBuilder: (_, __) => const SizedBox(height: 10))),
    const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: Icon(Icons.auto_awesome_rounded, color: _SetupColors.warning, size: 28))),
  ]);
}

class _SetupHeading extends StatelessWidget { const _SetupHeading({required this.title, required this.description}); final String title; final String description; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, height: 1.15, letterSpacing: -.7, fontWeight: FontWeight.w800, color: _SetupColors.text)), const SizedBox(height: 10), Text(description, style: const TextStyle(fontSize: 16, height: 1.45, color: _SetupColors.secondaryText))]); }

class PrimarySetupButton extends StatelessWidget { const PrimarySetupButton({super.key, required this.label, required this.enabled, required this.onPressed}); final String label; final bool enabled; final VoidCallback onPressed; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 20), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: enabled ? onPressed : null, style: ElevatedButton.styleFrom(backgroundColor: _SetupColors.primary, disabledBackgroundColor: _SetupColors.strongBorder, foregroundColor: Colors.white, disabledForegroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text(label)))); }

class ProvinceCard extends StatelessWidget { const ProvinceCard({super.key, required this.province, required this.selected, required this.onTap}); final Province province; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => _SelectableCard(selected: selected, onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: province.color, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.location_city_outlined, color: _SetupColors.text)), const Spacer(), Text(province.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _SetupColors.text)), const SizedBox(height: 3), Text(province.learners, style: const TextStyle(fontSize: 12, color: _SetupColors.secondaryText))])); }

class TopicCard extends StatelessWidget { const TopicCard({super.key, required this.topic, required this.selected, required this.onTap}); final Topic topic; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => _SelectableCard(selected: selected, onTap: onTap, child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: topic.color, borderRadius: BorderRadius.circular(13)), child: Icon(topic.icon, color: _SetupColors.text)), const SizedBox(width: 11), Expanded(child: Text(topic.label, style: const TextStyle(fontWeight: FontWeight.w800, color: _SetupColors.text))), AnimatedScale(scale: selected ? 1 : .75, duration: const Duration(milliseconds: 200), child: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? _SetupColors.primary : _SetupColors.strongBorder))])); }

class LearningGoalCard extends StatelessWidget { const LearningGoalCard({super.key, required this.goal, required this.selected, required this.onTap}); final Goal goal; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => _SelectableCard(selected: selected, onTap: onTap, padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: goal.color, shape: BoxShape.circle), child: Icon(goal.icon, color: _SetupColors.text)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w800, color: _SetupColors.text)), const SizedBox(height: 4), Text(goal.description, style: const TextStyle(fontSize: 12.5, height: 1.3, color: _SetupColors.secondaryText))])), Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? _SetupColors.primary : _SetupColors.strongBorder)])); }

class _SelectableCard extends StatelessWidget { const _SelectableCard({required this.selected, required this.onTap, required this.child, this.padding = const EdgeInsets.all(14)}); final bool selected; final VoidCallback onTap; final Widget child; final EdgeInsets padding; @override Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Ink(padding: padding, decoration: BoxDecoration(color: selected ? const Color(0xFFEAF9EF) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? _SetupColors.primary : _SetupColors.border, width: selected ? 1.5 : 1)), child: AnimatedScale(scale: selected ? 1 : .99, duration: const Duration(milliseconds: 220), child: child)))); }
class _InfoCard extends StatelessWidget { const _InfoCard(); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _SetupColors.subtle, borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.lightbulb_outline_rounded, color: _SetupColors.warning), SizedBox(width: 10), Expanded(child: Text('You can update your topics anytime from your profile settings.', style: TextStyle(fontSize: 13, height: 1.35, color: _SetupColors.secondaryText)))])); }

class Province { const Province(this.name, this.learners, this.color); final String name; final String learners; final Color color; }
class Topic { const Topic(this.label, this.icon, this.color); final String label; final IconData icon; final Color color; }
class Goal { const Goal(this.value, this.title, this.description, this.icon, this.color); final LearningGoal value; final String title; final String description; final IconData icon; final Color color; }
const _provinces = [Province('Phnom Penh', '1,234 learners', Color(0xFFE2F3FE)), Province('Siem Reap', '1,134 learners', Color(0xFFFFF3C4)), Province('Battambang', '986 learners', Color(0xFFEAF9EF)), Province('Kampot', '845 learners', Color(0xFFFFE5EC)), Province('Mondulkiri', '612 learners', Color(0xFFEAE7FF)), Province('Sihanoukville', '1,025 learners', Color(0xFFFFEBD6)), Province('Kandal', '764 learners', Color(0xFFE2F3FE)), Province('Kep', '490 learners', Color(0xFFEAF9EF))];
const _topics = [Topic('Math', Icons.functions_rounded, Color(0xFFE2F3FE)), Topic('Physics', Icons.bolt_rounded, Color(0xFFFFF3C4)), Topic('Chemistry', Icons.science_outlined, Color(0xFFEAF9EF)), Topic('Biology', Icons.eco_outlined, Color(0xFFEAF9EF)), Topic('Science', Icons.biotech_outlined, Color(0xFFEAE7FF)), Topic('Geography', Icons.public_rounded, Color(0xFFE2F3FE)), Topic('Programming', Icons.code_rounded, Color(0xFFFFEBD6)), Topic('Technology', Icons.memory_rounded, Color(0xFFEAE7FF)), Topic('English', Icons.translate_rounded, Color(0xFFFFE5EC)), Topic('Design', Icons.palette_outlined, Color(0xFFFFF3C4)), Topic('Business', Icons.trending_up_rounded, Color(0xFFEAF9EF)), Topic('History', Icons.account_balance_outlined, Color(0xFFE2F3FE))];
const _goals = [Goal(LearningGoal.learn, 'Learn something new', 'Explore lessons and build real understanding.', Icons.menu_book_rounded, Color(0xFFEAF9EF)), Goal(LearningGoal.compete, 'Compete with others', 'Join challenges and climb the leaderboard.', Icons.emoji_events_outlined, Color(0xFFFFF3C4)), Goal(LearningGoal.streak, 'Build a learning streak', 'Stay consistent and grow every day.', Icons.local_fire_department_outlined, Color(0xFFE2F3FE)), Goal(LearningGoal.community, 'Meet other learners', 'Connect, share, and grow together.', Icons.groups_2_outlined, Color(0xFFEAE7FF))];
abstract final class _SetupColors { static const primary = Color(0xFF22C55E); static const text = Color(0xFF0F1419); static const secondaryText = Color(0xFF536471); static const tertiaryText = Color(0xFF8B98A5); static const subtle = Color(0xFFF7F9F9); static const border = Color(0xFFEFF3F4); static const strongBorder = Color(0xFFCFD9DE); static const warning = Color(0xFFFFD400); }
