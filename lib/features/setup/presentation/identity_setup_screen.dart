import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_setup_provider.dart';

enum IdentityStep { intro, avatar, username, bio, reveal }

class IdentitySetupScreen extends ConsumerStatefulWidget {
  const IdentitySetupScreen({super.key, required this.step});
  final IdentityStep step;

  @override
  ConsumerState<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends ConsumerState<IdentitySetupScreen> {
  late final TextEditingController _username = TextEditingController();
  late final TextEditingController _bio = TextEditingController();
  late final PageController _avatars = PageController(viewportFraction: .56);

  @override
  void dispose() { _username.dispose(); _bio.dispose(); _avatars.dispose(); super.dispose(); }

  Future<void> _next(ProfileSetupState state) async {
    switch (widget.step) {
      case IdentityStep.intro:
        context.go('/identity/avatar');
        return;
      case IdentityStep.avatar:
        if (state.avatarId != null) context.go('/identity/username');
        return;
      case IdentityStep.username:
        final value = _username.text.trim().replaceFirst(RegExp('^@'), '');
        if (value.length >= 3) {
          ref.read(profileSetupProvider.notifier).setUsername(value);
          context.go('/identity/bio');
        }
        return;
      case IdentityStep.bio:
        ref.read(profileSetupProvider.notifier).setBio(_bio.text.trim());
        context.go('/identity/reveal');
        return;
      case IdentityStep.reveal:
        await ref.read(profileSetupProvider.notifier).complete();
        if (mounted) context.go('/home');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(profileSetupProvider);
    return setup.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: _IdentityColors.primary))),
      error: (_, __) => const Scaffold(body: Center(child: Text('Unable to load your profile setup.'))),
      data: (state) {
        _username.value = _username.value.copyWith(text: _username.text.isEmpty ? (state.username ?? '') : _username.text);
        _bio.value = _bio.value.copyWith(text: _bio.text.isEmpty ? state.bio : _bio.text);
        final enabled = switch (widget.step) { IdentityStep.avatar => state.avatarId != null, IdentityStep.username => _username.text.trim().replaceFirst('@', '').length >= 3, _ => true };
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(child: Column(children: [
            _IdentityHeader(step: widget.step),
            IdentityProgressIndicator(activeStep: widget.step.index + 1),
            const SizedBox(height: 24),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _content(state)))),
            _IdentityButton(label: _buttonLabel, enabled: enabled, onPressed: () => _next(state)),
          ])),
        );
      },
    );
  }

  String get _buttonLabel => switch (widget.step) { IdentityStep.intro => 'Let\'s get started  \u2192', IdentityStep.avatar => 'Choose this avatar', IdentityStep.username || IdentityStep.bio => 'Continue  \u2192', IdentityStep.reveal => 'Let\'s go to RIKSA  \u2192' };

  Widget _content(ProfileSetupState state) => switch (widget.step) {
    IdentityStep.intro => const _IdentityIntro(),
    IdentityStep.avatar => _AvatarStep(selected: state.avatarId, pageController: _avatars, onSelected: ref.read(profileSetupProvider.notifier).selectAvatar),
    IdentityStep.username => _UsernameStep(controller: _username, onChanged: () => setState(() {})),
    IdentityStep.bio => _BioStep(controller: _bio, selected: state.interests, onChanged: () => setState(() {}), onInterest: ref.read(profileSetupProvider.notifier).toggleInterest),
    IdentityStep.reveal => _ProfileReveal(state: state),
  };
}

class _IdentityHeader extends StatelessWidget { const _IdentityHeader({required this.step}); final IdentityStep step; @override Widget build(BuildContext context) => SizedBox(height: 48, child: Row(children: [const SizedBox(width: 12), IconButton(onPressed: step == IdentityStep.intro ? null : () => context.go(_previousRoute(step)), icon: Icon(Icons.arrow_back_rounded, color: step == IdentityStep.intro ? _IdentityColors.tertiary : _IdentityColors.text))])); }
String _previousRoute(IdentityStep step) => switch (step) { IdentityStep.avatar => '/identity/intro', IdentityStep.username => '/identity/avatar', IdentityStep.bio => '/identity/username', IdentityStep.reveal => '/identity/bio', IdentityStep.intro => '/setup/goal' };

class IdentityProgressIndicator extends StatelessWidget { const IdentityProgressIndicator({super.key, required this.activeStep}); final int activeStep; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 36), child: Row(children: List.generate(9, (index) { if (index.isOdd) return Expanded(child: Container(height: 2, color: index ~/ 2 < activeStep - 1 ? _IdentityColors.primary : _IdentityColors.border)); final step = index ~/ 2 + 1; final done = step < activeStep; final active = step == activeStep; return AnimatedContainer(duration: const Duration(milliseconds: 240), width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: done || active ? _IdentityColors.primary : _IdentityColors.subtle, border: Border.all(color: done || active ? _IdentityColors.primary : _IdentityColors.strongBorder)), child: Center(child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : _IdentityColors.secondary)))); })));
}

class _IdentityIntro extends StatelessWidget { const _IdentityIntro(); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _IdentityTitle(title: 'Let\'s create your\nRIKSA identity ✦', description: 'A few quick steps to make your profile feel like you.'), const Spacer(), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _IdentityColors.subtle, borderRadius: BorderRadius.circular(22), border: Border.all(color: _IdentityColors.border)), child: const Column(children: [_IntroItem(Icons.face_retouching_natural_rounded, 'Choose your avatar', Color(0xFFE2F3FE)), _IntroItem(Icons.alternate_email_rounded, 'Create your username', Color(0xFFEAF9EF)), _IntroItem(Icons.edit_note_rounded, 'Tell us about you', Color(0xFFFFF3C4)), _IntroItem(Icons.auto_awesome_rounded, 'You\'re ready', Color(0xFFFFE5EC))])), const Spacer(), Center(child: Transform.rotate(angle: -.08, child: const Icon(Icons.pets_rounded, color: _IdentityColors.primary, size: 104))), const SizedBox(height: 22)]); }
class _IntroItem extends StatelessWidget { const _IntroItem(this.icon, this.label, this.color); final IconData icon; final String label; final Color color; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: _IdentityColors.text)), const SizedBox(width: 13), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _IdentityColors.text))])); }

class _AvatarStep extends StatelessWidget { const _AvatarStep({required this.selected, required this.pageController, required this.onSelected}); final String? selected; final PageController pageController; final ValueChanged<String> onSelected; @override Widget build(BuildContext context) => Column(children: [const _IdentityTitle(title: 'Choose your avatar', description: 'Pick an avatar that feels like you. You can change it anytime.'), const SizedBox(height: 28), Expanded(child: PageView.builder(controller: pageController, itemCount: _avatars.length, onPageChanged: (index) => onSelected(_avatars[index].id), itemBuilder: (_, index) { final avatar = _avatars[index]; final active = selected == avatar.id; return AnimatedScale(duration: const Duration(milliseconds: 280), scale: active ? 1 : .84, child: _AvatarFace(avatar: avatar, large: true)); })), const Text('Nova', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _IdentityColors.text)), const SizedBox(height: 4), const Text('Curious explorer', style: TextStyle(color: _IdentityColors.secondary)), const SizedBox(height: 12), const Wrap(spacing: 8, children: [_Tag('Curious'), _Tag('Creative'), _Tag('Learner')]), const SizedBox(height: 18), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.circle, size: 8, color: _IdentityColors.primary), Icon(Icons.circle, size: 8, color: _IdentityColors.strongBorder), Icon(Icons.circle, size: 8, color: _IdentityColors.strongBorder)]), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_outlined, size: 18), label: const Text('Upload my own'), style: TextButton.styleFrom(foregroundColor: _IdentityColors.secondary))]); }
class _AvatarFace extends StatelessWidget { const _AvatarFace({required this.avatar, this.large = false}); final Avatar avatar; final bool large; @override Widget build(BuildContext context) => Container(width: large ? 185 : 56, height: large ? 185 : 56, decoration: BoxDecoration(shape: BoxShape.circle, color: avatar.color, border: Border.all(color: Colors.white, width: 5)), child: Icon(avatar.icon, size: large ? 92 : 28, color: _IdentityColors.text)); }
class _Tag extends StatelessWidget { const _Tag(this.text); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _IdentityColors.subtle, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 12, color: _IdentityColors.secondary))); }

class _UsernameStep extends StatelessWidget { const _UsernameStep({required this.controller, required this.onChanged}); final TextEditingController controller; final VoidCallback onChanged; @override Widget build(BuildContext context) { final value = controller.text.trim().replaceFirst('@', ''); final available = value.length >= 3; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _IdentityTitle(title: 'What should we call you?', description: 'Choose how you\'ll show up in the RIKSA community.'), const SizedBox(height: 28), TextField(controller: controller, onChanged: (_) => onChanged(), autocorrect: false, decoration: InputDecoration(prefixText: '@ ', hintText: 'riksa_leap', filled: true, fillColor: _IdentityColors.subtle, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _IdentityColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _IdentityColors.strongBorder))), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 12), AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: available ? Container(key: const ValueKey('available'), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF9EF), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.check_circle_rounded, color: _IdentityColors.success, size: 18), SizedBox(width: 8), Text('Great! That username is available.', style: TextStyle(color: _IdentityColors.success, fontWeight: FontWeight.w600))])) : const SizedBox.shrink()), const Spacer(), const Text('Your name can always change later.', style: TextStyle(color: _IdentityColors.tertiary))]); }}

class _BioStep extends StatelessWidget { const _BioStep({required this.controller, required this.selected, required this.onChanged, required this.onInterest}); final TextEditingController controller; final Set<String> selected; final VoidCallback onChanged; final ValueChanged<String> onInterest; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _IdentityTitle(title: 'What\'s your vibe?', description: 'Tell your community what you\'re learning, building, or curious about.'), const SizedBox(height: 22), TextField(controller: controller, onChanged: (_) => onChanged(), maxLength: 160, minLines: 5, maxLines: 5, decoration: InputDecoration(hintText: 'I\'m learning Flutter, building cool apps, and exploring AI...', filled: true, fillColor: _IdentityColors.subtle, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _IdentityColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _IdentityColors.border)))), const SizedBox(height: 10), const Text('A few interests', style: TextStyle(fontWeight: FontWeight.w800, color: _IdentityColors.text)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: _interests.map((interest) => FilterChip(label: Text(interest), selected: selected.contains(interest), onSelected: (_) => onInterest(interest), selectedColor: const Color(0xFFEAF9EF), checkmarkColor: _IdentityColors.primary, side: BorderSide(color: selected.contains(interest) ? _IdentityColors.primary : _IdentityColors.border))).toList()), const Spacer(), Center(child: TextButton(onPressed: () => context.go('/identity/reveal'), child: const Text('Skip for now')))]); }
class _ProfileReveal extends StatelessWidget { const _ProfileReveal({required this.state}); final ProfileSetupState state; @override Widget build(BuildContext context) => Column(children: [const _IdentityTitle(title: 'You\'re all set!', description: 'Welcome to your RIKSA era.'), const Spacer(), Transform.rotate(angle: -.02, child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _IdentityColors.strongBorder)), child: Column(children: [_AvatarFace(avatar: _avatars.firstWhere((item) => item.id == state.avatarId, orElse: () => _avatars.first)), const SizedBox(height: 12), Text('@${state.username ?? 'learner'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _IdentityColors.text)), const SizedBox(height: 6), Text('${state.province ?? 'Cambodia'}, Cambodia', style: const TextStyle(color: _IdentityColors.secondary)), const SizedBox(height: 12), Wrap(spacing: 6, children: state.topics.take(3).map((t) => _Tag(t)).toList()), if (state.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Text(state.bio, textAlign: TextAlign.center, style: const TextStyle(color: _IdentityColors.secondary))), const SizedBox(height: 12), const Text('Learning. Building. Growing.', style: TextStyle(fontWeight: FontWeight.w700, color: _IdentityColors.primary))]))), const Spacer(), const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Icon(Icons.auto_awesome_rounded, color: _IdentityColors.warning), Icon(Icons.favorite_border_rounded, color: Color(0xFFF91880)), Icon(Icons.star_border_rounded, color: _IdentityColors.primary)]), const SizedBox(height: 22)]); }

class _IdentityTitle extends StatelessWidget { const _IdentityTitle({required this.title, required this.description}); final String title; final String description; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, height: 1.13, letterSpacing: -.8, fontWeight: FontWeight.w800, color: _IdentityColors.text)), const SizedBox(height: 10), Text(description, style: const TextStyle(fontSize: 16, height: 1.45, color: _IdentityColors.secondary))]); }
class _IdentityButton extends StatelessWidget { const _IdentityButton({required this.label, required this.enabled, required this.onPressed}); final String label; final bool enabled; final VoidCallback onPressed; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 20), child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: enabled ? onPressed : null, style: ElevatedButton.styleFrom(backgroundColor: _IdentityColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: _IdentityColors.strongBorder, disabledForegroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text(label)))); }
/// TODO(design): Replace these icon-based avatar placeholders with final RIKSA
/// mascot/avatar assets when they are ready.
class Avatar { const Avatar(this.id, this.icon, this.color); final String id; final IconData icon; final Color color; }
const _avatars = [Avatar('nova', Icons.face_3_rounded, Color(0xFFE2F3FE)), Avatar('milo', Icons.face_2_rounded, Color(0xFFFFF3C4)), Avatar('luna', Icons.face_4_rounded, Color(0xFFEAE7FF))];
const _interests = ['Coding', 'Learning', 'Design', 'Science', 'Sports', 'Music', 'Business', 'Travel'];
abstract final class _IdentityColors { static const primary = Color(0xFF22C55E); static const text = Color(0xFF0F1419); static const secondary = Color(0xFF536471); static const tertiary = Color(0xFF8B98A5); static const subtle = Color(0xFFF7F9F9); static const border = Color(0xFFEFF3F4); static const strongBorder = Color(0xFFCFD9DE); static const success = Color(0xFF00BA7C); static const warning = Color(0xFFFFD400); }
