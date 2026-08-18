import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_navbar.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/riksa_drawer.dart';
import '../../auth/providers/auth_provider.dart';

const purple = Color(0xFF7C5CFF);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = ScrollController();
  bool _dark = false, _compact = false;
  int _tab = 0, _nav = 0;
  double _last = 0;
  @override void initState() {
    super.initState();
    _controller.addListener(_scroll);
  }
  void _scroll() {
    final now = _controller.offset;
    final delta = now - _last;
    _last = now;
    if (!_compact && now > 28 && delta > 4) setState(() => _compact = true);
    if (_compact && delta < -4) setState(() => _compact = false);
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => HomeMode(
    dark: _dark,
    child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: _dark ? const Color(0xFF0E1015) : const Color(0xFFF8F7FA),
      drawerScrimColor: Colors.black.withValues(alpha: _dark ? .55 : .42),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * .84,
        elevation: 18,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
        child: RiksaDrawer(
          dark: _dark,
          fullName: 'Vichhean Sombath',
          username: 'vichhean_sombath',
          onLogout: () async {
            Navigator.of(context).pop();
            await ref.read(authProvider.notifier).logout();
          },
        ),
      ),
      body: Stack(children: [
      SafeArea(bottom: false, child: SingleChildScrollView(
        controller: _controller,
        padding: EdgeInsets.fromLTRB(20, _compact ? 10 : 20, 20, 160),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppHeader(dark: _dark, compact: _compact, onMenu: () => _scaffoldKey.currentState?.openDrawer(), onTheme: () {}),
          SizedBox(height: _compact ? 18 : 36),
          CategoryTabs(selected: _tab, onTap: (i) => setState(() => _tab = i)),
          const SizedBox(height: 20), const StreakCard(), const SizedBox(height: 30),
          const Leaderboard(), const SizedBox(height: 30), const CommunityPost(),
        ]))),
      )),
      Align(alignment: Alignment.bottomCenter, child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: SizedBox(height: 148, child: Stack(clipBehavior: Clip.none, children: [
          AdaptiveNavbar(
            compact: _compact,
            dark: _dark,
            selectedIndex: _nav,
            onDestinationSelected: (i) => setState(() {
              if (i == 1) {
                context.go('/blog');
                return;
              }
              _nav = i;
              _compact = false;
            }),
          ),
          Positioned(
            right: 14,
            bottom: 86,
            child: AiOrb(compact: _compact, onTap: () => _ai(context)),
          ),
        ])),
      ))),
    ]),
    ),
  );
  void _ai(BuildContext context) => showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (_) => const AiSheet());
}

class HomeMode extends InheritedWidget { const HomeMode({required this.dark, required super.child, super.key}); final bool dark; static bool of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<HomeMode>()!.dark; @override bool updateShouldNotify(HomeMode old) => old.dark != dark; }
Color bg(BuildContext c) => HomeMode.of(c) ? const Color(0xFF0E1015) : const Color(0xFFF8F7FA);
Color ink(BuildContext c) => HomeMode.of(c) ? const Color(0xFFF5F5F7) : const Color(0xFF17171C);
Color muted(BuildContext c) => HomeMode.of(c) ? const Color(0xFF9499A6) : const Color(0xFF92959D);
Color surface(BuildContext c) => HomeMode.of(c) ? const Color(0xFF151821) : Colors.white;

class Header extends StatelessWidget {
  const Header({required this.dark, required this.compact, required this.onMenu, required this.onTheme, super.key});
  final bool dark, compact; final VoidCallback onMenu, onTheme;
  @override Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(milliseconds: 250), height: compact ? 48 : 62, child: Row(children: [
    CircleButton(icon: Icons.menu_rounded, dark: dark, onTap: onMenu), const Spacer(), ThemeSwitch(dark: dark, onTap: onTheme), const SizedBox(width: 12), CreateButton(dark: dark),
  ]));
}
class CircleButton extends StatelessWidget { const CircleButton({required this.icon, required this.dark, required this.onTap, super.key}); final IconData icon; final bool dark; final VoidCallback onTap; @override Widget build(BuildContext c) => Material(color: dark ? const Color(0xFF20242E) : Colors.white, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 58, height: 58, child: Icon(icon, size: 29, color: dark ? Colors.white : const Color(0xFF41444B))))); }
class ThemeSwitch extends StatelessWidget { const ThemeSwitch({required this.dark, required this.onTap, super.key}); final bool dark; final VoidCallback onTap; @override Widget build(BuildContext c) => GestureDetector(onTap: onTap, child: Container(width: 116,height: 58,padding: const EdgeInsets.all(4),decoration: BoxDecoration(color: dark ? const Color(0xFF20242E) : const Color(0xFFF0F0F4),borderRadius: BorderRadius.circular(30)),child: Stack(children: [AnimatedAlign(duration: const Duration(milliseconds: 250),curve: Curves.easeOutCubic,alignment: dark ? Alignment.centerLeft : Alignment.centerRight,child: const CircleAvatar(radius: 25,backgroundColor: Color(0xFFFCFCFF))),Align(alignment: Alignment.centerLeft,child: Padding(padding: const EdgeInsets.only(left: 16),child: Icon(Icons.nightlight_round,color: dark ? purple : muted(c)))),Align(alignment: Alignment.centerRight,child: Padding(padding: const EdgeInsets.only(right: 16),child: const Icon(Icons.light_mode_rounded,color: Color(0xFFFFAB00)))) ]))); }
class CreateButton extends StatefulWidget { const CreateButton({required this.dark, super.key}); final bool dark; @override State<CreateButton> createState() => _CreateButtonState(); }
class _CreateButtonState extends State<CreateButton> { bool down = false; @override Widget build(BuildContext c) => GestureDetector(onTapDown: (_) => setState(() => down = true),onTapCancel: () => setState(() => down = false),onTapUp: (_) => setState(() => down = false),child: AnimatedRotation(duration: const Duration(milliseconds: 180),turns: down ? .125 : 0,child: AnimatedScale(duration: const Duration(milliseconds: 180),scale: down ? .92 : 1,child: Container(width: 58,height: 58,decoration: BoxDecoration(shape: BoxShape.circle,gradient: const LinearGradient(colors: [Color(0xFFB9AAFF),purple]),boxShadow: [BoxShadow(color: purple.withValues(alpha: .28),blurRadius: 18)]),child: const Icon(Icons.add_rounded,color: Colors.white,size: 34))))); }

class CategoryTabs extends StatelessWidget { const CategoryTabs({required this.selected, required this.onTap, super.key}); final int selected; final ValueChanged<int> onTap; @override Widget build(BuildContext c) { const names = ['For You','Communities','Lessons']; return Row(children: List.generate(3, (i) { final active = i == selected; return Expanded(child: InkWell(onTap: () => onTap(i), child: Column(children: [Text(names[i],style: TextStyle(color: active ? ink(c) : muted(c),fontWeight: active ? FontWeight.w800 : FontWeight.w600,fontSize: 14)),const SizedBox(height: 9),AnimatedContainer(duration: const Duration(milliseconds: 220),curve: Curves.easeOutCubic,width: active ? 48 : 0,height: 3,decoration: BoxDecoration(color: purple,borderRadius: BorderRadius.circular(3))) ]))); })); } }

class StreakCard extends StatelessWidget { const StreakCard({super.key}); @override Widget build(BuildContext c) { final dark = HomeMode.of(c); return Container(height: 250,padding: const EdgeInsets.all(24),decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),gradient: dark ? const LinearGradient(colors: [Color(0xFF1B1A35),Color(0xFF32255B)]) : const LinearGradient(colors: [Colors.white,Color(0xFFF0EBFF),Color(0xFFFFEDF3)]),boxShadow: [BoxShadow(color: purple.withValues(alpha: .16),blurRadius: 28,offset: const Offset(0,12))]),child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Align(alignment: Alignment.topRight,child: GlassPill(child: const Text('Upgrade Streak  ›',style: TextStyle(color: purple,fontWeight: FontWeight.w800)))),Text('187',style: TextStyle(color: ink(c),fontSize: 54,fontWeight: FontWeight.w900,height: .85)),const SizedBox(height: 10),Text('Day Streak',style: TextStyle(color: ink(c),fontSize: 17,fontWeight: FontWeight.w900)),const SizedBox(height: 8),SizedBox(width: 205,child: Text("Keep going! You're building something amazing every day.",style: TextStyle(color: muted(c),height: 1.4))),const Spacer(),Row(children: List.generate(7,(i) => Container(width: 11,height: 11,margin: const EdgeInsets.only(right: 9),decoration: BoxDecoration(shape: BoxShape.circle,color: i < 4 ? purple : purple.withValues(alpha: .18))))) ]),const Positioned(right: 5,bottom: 12,child: Lotus())])); } }
class Lotus extends StatelessWidget { const Lotus({super.key}); @override Widget build(BuildContext c) => Stack(alignment: Alignment.center,children: [Container(width: 135,height: 135,decoration: BoxDecoration(shape: BoxShape.circle,gradient: RadialGradient(colors: [const Color(0xFFBC82FF).withValues(alpha: .5),Colors.transparent]))),Transform.rotate(angle: .28,child: Container(width: 80,height: 100,decoration: BoxDecoration(borderRadius: BorderRadius.circular(45),gradient: const LinearGradient(colors: [Color(0xFFFFBDEA),Color(0xFFA051FF),Color(0xFFFFE176)]),boxShadow: [BoxShadow(color: purple.withValues(alpha: .35),blurRadius: 20)]))),const Icon(Icons.auto_awesome_rounded,color: Colors.white,size: 27)]); }

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(icon: Icons.emoji_events_rounded, title: 'Leaderboard', action: 'See all'),
      const SizedBox(height: 20),
      SizedBox(
        height: 250,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Expanded(child: Podium(rank: 2, name: '@sokha', xp: '1,980 XP', height: 100, color: Color(0xFFDCD5FF))),
            Expanded(child: Podium(rank: 1, name: '@riksa', xp: '2,450 XP', height: 130, color: Color(0xFFFFE3A2))),
            Expanded(child: Podium(rank: 3, name: '@dara', xp: '1,420 XP', height: 84, color: Color(0xFFFFD7BE))),
          ],
        ),
      ),
    ],
  );
}

class Podium extends StatelessWidget {
  const Podium({required this.rank, required this.name, required this.xp, required this.height, required this.color, super.key});

  final int rank;
  final String name;
  final String xp;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Icon(Icons.workspace_premium_rounded, color: rank == 1 ? const Color(0xFFFFB000) : muted(context)),
      CircleAvatar(radius: rank == 1 ? 27 : 23, backgroundColor: color, child: Icon(Icons.face_rounded, color: ink(context))),
      const SizedBox(height: 5),
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink(context), fontWeight: FontWeight.w900)),
      Text(xp, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted(context), fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        height: height,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: .7), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Text('$rank', style: TextStyle(color: ink(context), fontWeight: FontWeight.w900)),
      ),
    ],
  );
}

class CommunityPost extends StatelessWidget {
  const CommunityPost({super.key});
  @override Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SectionTitle(icon: Icons.local_fire_department_rounded, title: 'From the Community', action: 'Latest'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface(c).withValues(alpha: .82), borderRadius: BorderRadius.circular(26)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const CircleAvatar(radius: 20, backgroundColor: Color(0xFFFFD5BB), child: Icon(Icons.science_rounded, color: purple)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('riksa / science', style: TextStyle(color: ink(c), fontWeight: FontWeight.w900)), Text('by Vichhean Sombath', style: TextStyle(color: muted(c), fontSize: 11))])), Text('2d ago', style: TextStyle(color: muted(c), fontSize: 11)), Icon(Icons.more_vert_rounded, color: muted(c))]),
      const SizedBox(height: 15), const PostMedia(), const SizedBox(height: 14),
      Text('Learning becomes more powerful when we share what we discover.', style: TextStyle(color: ink(c), fontWeight: FontWeight.w600, height: 1.4)),
      const SizedBox(height: 15),
      Row(children: [const Icon(Icons.favorite_rounded, color: Color(0xFFFF667E)), const SizedBox(width: 5), Text('187', style: TextStyle(color: ink(c))), const SizedBox(width: 22), Icon(Icons.chat_bubble_outline_rounded, color: ink(c)), const SizedBox(width: 5), Text('24', style: TextStyle(color: ink(c))), const Spacer(), Icon(Icons.bookmark_border_rounded, color: ink(c))]),
    ])),
  ]);
}
class PostMedia extends StatelessWidget { const PostMedia({super.key}); @override Widget build(BuildContext c) => Container(height: 198,decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),gradient: LinearGradient(colors: HomeMode.of(c) ? const [Color(0xFF24384A),Color(0xFF403164)] : const [Color(0xFFC3E9EA),Color(0xFFB5A7FF),Color(0xFFFFD0AB)])),child: Stack(children: [Center(child: Container(width: 110,height: 110,decoration: BoxDecoration(shape: BoxShape.circle,color: Colors.white.withValues(alpha: .35),border: Border.all(color: Colors.white.withValues(alpha: .7))),child: const Icon(Icons.science_rounded,size: 52,color: Color(0xFF604ACA)))),const Positioned(left: 12,bottom: 12,child: GlassPill(child: Text('Science'))),const Positioned(right: 12,bottom: 12,child: GlassPill(child: Text('67 liked')))])); }

class AiOrb extends StatefulWidget { const AiOrb({required this.compact,required this.onTap,super.key}); final bool compact; final VoidCallback onTap; @override State<AiOrb> createState() => _AiOrbState(); }
class _AiOrbState extends State<AiOrb> { bool down = false; @override Widget build(BuildContext c) => GestureDetector(onTapDown: (_) => setState(() => down = true),onTapCancel: () => setState(() => down = false),onTapUp: (_) { setState(() => down = false); widget.onTap(); },child: AnimatedContainer(duration: const Duration(milliseconds: 300),width: widget.compact ? 50 : 62,height: widget.compact ? 50 : 62,child: AnimatedScale(duration: const Duration(milliseconds: 160),scale: down ? .92 : 1,child: Container(decoration: BoxDecoration(shape: BoxShape.circle,gradient: const LinearGradient(colors: [Colors.white,Color(0xFFE1D9FF)]),border: Border.all(color: Colors.white,width: 2),boxShadow: [BoxShadow(color: purple.withValues(alpha: .48),blurRadius: 23)]),child: const Column(mainAxisAlignment: MainAxisAlignment.center,children: [Icon(Icons.auto_awesome_rounded,color: purple,size: 19),Text('AI',style: TextStyle(color: purple,fontSize: 10,fontWeight: FontWeight.w900))]))))); }
class AiSheet extends StatelessWidget {
  const AiSheet({super.key});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: surface(c).withValues(alpha: .96), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Riksa AI', style: TextStyle(color: purple, fontWeight: FontWeight.w900)), const SizedBox(height: 8),
    Text('How can I help you?', style: TextStyle(color: ink(c), fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: bg(c), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Expanded(child: Text('Ask anything...')), Icon(Icons.arrow_upward_rounded, color: purple)])),
    const SizedBox(height: 14), const Wrap(spacing: 8, children: [Chip(label: Text('Explain')), Chip(label: Text('Quiz me')), Chip(label: Text('Summarize'))]),
  ]));
}
class SectionTitle extends StatelessWidget { const SectionTitle({required this.icon,required this.title,required this.action,super.key}); final IconData icon; final String title,action; @override Widget build(BuildContext c) => Row(children: [Icon(icon,color: const Color(0xFFFFA900)),const SizedBox(width: 8),Text(title,style: TextStyle(color: ink(c),fontSize: 19,fontWeight: FontWeight.w900)),const Spacer(),Text(action,style: TextStyle(color: muted(c),fontWeight: FontWeight.w700))]); }
class GlassPill extends StatelessWidget { const GlassPill({required this.child,super.key}); final Widget child; @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 7),decoration: BoxDecoration(color: Colors.white.withValues(alpha: .7),borderRadius: BorderRadius.circular(20)),child: child); }
