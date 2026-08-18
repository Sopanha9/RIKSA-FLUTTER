import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_navbar.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/riksa_drawer.dart';
import '../../auth/providers/auth_provider.dart';

const _purple = Color(0xFF7C5CFF);

class BlogScreen extends ConsumerStatefulWidget {
  const BlogScreen({super.key});
  @override ConsumerState<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends ConsumerState<BlogScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController(viewportFraction: .78);
  final _scrollController = ScrollController();
  var _dark = false;
  var _page = 0;
  var _category = 0;
  var _compact = false;
  var _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;
    if (!_compact && offset > 28 && delta > 4) setState(() => _compact = true);
    if (_compact && delta < -4) setState(() => _compact = false);
  }

  @override void dispose() { _scrollController.dispose(); _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final background = _dark ? const Color(0xFF0E1015) : const Color(0xFFF8F7FA);
    final text = _dark ? const Color(0xFFF5F5F7) : const Color(0xFF17171C);
    final muted = _dark ? const Color(0xFF9499A6) : const Color(0xFF92959D);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: background,
      drawerScrimColor: Colors.black.withValues(alpha: _dark ? .55 : .42),
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * .84,
        elevation: 18,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
        child: RiksaDrawer(
          dark: _dark,
          fullName: 'Vichhean Sombath',
          username: 'vichhean_sombath',
          onLogout: () async { Navigator.of(context).pop(); await ref.read(authProvider.notifier).logout(); },
        ),
      ),
      body: Stack(children: [
        SafeArea(child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppHeader(dark: _dark, compact: _compact, onMenu: () => _scaffoldKey.currentState?.openDrawer(), onTheme: () {}),
            const SizedBox(height: 24),
            Row(children: [Text('Blog', style: TextStyle(color: text, fontSize: 33, fontWeight: FontWeight.w900)), const SizedBox(width: 7), const Icon(Icons.auto_awesome_rounded, color: _purple, size: 20)]),
            const SizedBox(height: 6),
            SizedBox(width: 280, child: Text('Stories, ideas & knowledge\nworth exploring.', style: TextStyle(color: muted, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600))),
            const SizedBox(height: 32),
            _SectionHeader(icon: Icons.auto_awesome_rounded, title: "Editor's Pick", action: 'View all', text: text, muted: muted),
            const SizedBox(height: 15),
            _EditorsPickCarousel(
              controller: _pageController,
              onPageChanged: (value) => setState(() => _page = value),
            ),
            const SizedBox(height: 12),
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(_heroes.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), height: 6, width: i == _page ? 22 : 6, decoration: BoxDecoration(color: i == _page ? _purple : _purple.withValues(alpha: .18), borderRadius: BorderRadius.circular(8)))))),
            const SizedBox(height: 28),
            SizedBox(height: 46, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 9), itemBuilder: (context, i) => ChoiceChip(label: Text(_categories[i]), selected: i == _category, onSelected: (_) => setState(() => _category = i), selectedColor: _purple.withValues(alpha: .12), backgroundColor: _dark ? const Color(0xFF1A1D27) : Colors.white, side: BorderSide(color: i == _category ? _purple.withValues(alpha: .45) : (_dark ? const Color(0xFF303645) : const Color(0xFFE9E7EE))), labelStyle: TextStyle(color: i == _category ? _purple : text, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
            const SizedBox(height: 31),
            _SectionHeader(icon: Icons.trending_up_rounded, title: 'Trending this week', action: 'View all', text: text, muted: muted),
            const SizedBox(height: 14),
            ...List.generate(_trending.length, (i) => _TrendingItem(rank: i + 1, article: _trending[i], text: text, muted: muted)),
            const SizedBox(height: 28),
            _SectionHeader(icon: Icons.history_rounded, title: 'Latest Articles', action: 'See all', text: text, muted: muted),
            const SizedBox(height: 13),
            ..._latest.map((article) => _LatestTile(article: article, dark: _dark, text: text, muted: muted)),
          ]),
        )),
        Align(alignment: Alignment.bottomCenter, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: SizedBox(height: 148, child: Stack(clipBehavior: Clip.none, children: [
          AdaptiveNavbar(selectedIndex: 1, dark: _dark, compact: _compact, onDestinationSelected: (index) { setState(() => _compact = false); if (index == 0) context.go('/home'); }),
          Positioned(right: 14, bottom: 86, child: _AiButton(compact: _compact)),
        ]))))),
      ]),
    );
  }
}

class _BlogControls extends StatelessWidget { const _BlogControls({required this.dark, required this.onMenu, required this.onTheme}); final bool dark; final VoidCallback onMenu, onTheme; @override Widget build(BuildContext c) => Row(children: [Material(color: dark ? const Color(0xFF20242E) : Colors.white, shape: const CircleBorder(), child: InkWell(onTap: onMenu, customBorder: const CircleBorder(), child: SizedBox(width: 58, height: 58, child: Icon(Icons.menu_rounded, color: dark ? Colors.white : const Color(0xFF41444B), size: 29)))), const Spacer(), GestureDetector(onTap: onTheme, child: Container(width: 116, height: 58, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: dark ? const Color(0xFF20242E) : const Color(0xFFF0F0F4), borderRadius: BorderRadius.circular(30)), child: Stack(children: [AnimatedAlign(duration: const Duration(milliseconds: 220), alignment: dark ? Alignment.centerLeft : Alignment.centerRight, child: const CircleAvatar(radius: 25, backgroundColor: Color(0xFFFCFCFF))), Align(alignment: Alignment.centerLeft, child: Icon(Icons.nightlight_round, color: dark ? _purple : const Color(0xFF92959D))), const Align(alignment: Alignment.centerRight, child: Icon(Icons.light_mode_rounded, color: Color(0xFFFFAB00)))]))), const SizedBox(width: 12), Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFB9AAFF), _purple]), boxShadow: [BoxShadow(color: _purple.withValues(alpha: .28), blurRadius: 18)]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 34))]); }
class _SectionHeader extends StatelessWidget { const _SectionHeader({required this.icon, required this.title, required this.action, required this.text, required this.muted}); final IconData icon; final String title, action; final Color text, muted; @override Widget build(BuildContext c) => Row(children: [Icon(icon, color: _purple, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w900)), const Spacer(), Text(action, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 13))]); }
class _EditorsPickCarousel extends StatelessWidget {
  const _EditorsPickCarousel({required this.controller, required this.onPageChanged});
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 312,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.hasClients ? (controller.page ?? controller.initialPage.toDouble()) : controller.initialPage.toDouble();
        return PageView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          itemCount: _heroes.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            final difference = index - current;
            final distance = difference.abs().clamp(0.0, 1.0).toDouble();
            final scale = (1 - distance * .12).clamp(.88, 1.0).toDouble();
            final rotation = difference.clamp(-1.0, 1.0).toDouble() * .09;
            return Transform.translate(
              offset: Offset(0, 15 * distance),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..setEntry(3, 2, .001)..rotateY(rotation)..scale(scale),
                child: Opacity(opacity: (1 - distance * .18).clamp(.76, 1.0).toDouble(), child: _EditorsPickCard(article: _heroes[index], active: distance < .22)),
              ),
            );
          },
        );
      },
    ),
  );
}

class _EditorsPickCard extends StatelessWidget {
  const _EditorsPickCard({required this.article, required this.active});
  final _Article article;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(gradient: article.gradient, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: active ? .18 : .07), blurRadius: active ? 30 : 12, offset: const Offset(0, 10))]),
        child: Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: active ? .22 : .38), Colors.black.withValues(alpha: .80)])))),
          Positioned(left: 18, top: 18, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .20), borderRadius: BorderRadius.circular(14)), child: Text(article.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)))),
          Positioned(left: 19, right: 16, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.08)),
            const SizedBox(height: 10),
            Row(children: [const CircleAvatar(radius: 11, backgroundColor: Color(0xFFFFD5BB), child: Icon(Icons.face_rounded, size: 14, color: _purple)), const SizedBox(width: 7), Expanded(child: Text('${article.author} • ${article.time} • Jul 13', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .82), fontWeight: FontWeight.w600, fontSize: 10))), Opacity(opacity: active ? 1 : .55, child: InkWell(onTap: () => context.go('/blog/details'), customBorder: const CircleBorder(), child: Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .20), border: Border.all(color: Colors.white.withValues(alpha: .35))), child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18))))])
          ])),
        ]),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget { const _HeroCard({required this.article}); final _Article article; @override Widget build(BuildContext c) => ClipRRect(borderRadius: BorderRadius.circular(24), child: Container(decoration: BoxDecoration(gradient: article.gradient), child: Stack(children: [Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .78)])))), Positioned(left: 18, top: 18, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .20), borderRadius: BorderRadius.circular(14)), child: Text(article.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)))), Positioned(left: 19, right: 19, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.08)), const SizedBox(height: 10), Row(children: [const CircleAvatar(radius: 11, backgroundColor: Color(0xFFFFD5BB), child: Icon(Icons.face_rounded, size: 14, color: _purple)), const SizedBox(width: 7), Expanded(child: Text('${article.author} • ${article.time} • Jul 13', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontWeight: FontWeight.w600, fontSize: 11))), Container(width: 34, height: 34, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: const Icon(Icons.arrow_forward_rounded, color: _purple, size: 18))])]))]))); }
class _TrendingItem extends StatelessWidget { const _TrendingItem({required this.rank, required this.article, required this.text, required this.muted}); final int rank; final _Article article; final Color text, muted; @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Row(children: [SizedBox(width: 35, child: Text(rank.toString().padLeft(2, '0'), style: const TextStyle(color: _purple, fontWeight: FontWeight.w900, fontSize: 17))), Container(width: 59, height: 59, decoration: BoxDecoration(gradient: article.gradient, borderRadius: BorderRadius.circular(15))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.w800, height: 1.18)), const SizedBox(height: 5), Text('${article.category} • ${article.time}', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))]))])); }
class _LatestTile extends StatelessWidget { const _LatestTile({required this.article, required this.dark, required this.text, required this.muted}); final _Article article; final bool dark; final Color text, muted; @override Widget build(BuildContext c) => Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () {}, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Container(width: 116, height: 86, decoration: BoxDecoration(gradient: article.gradient, borderRadius: BorderRadius.circular(17))), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.category.toUpperCase(), style: const TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6)), const SizedBox(height: 4), Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w900, height: 1.18)), const SizedBox(height: 7), Text('${article.author} • ${article.time} • Jul 13', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600))])), Icon(Icons.bookmark_border_rounded, color: muted)])))); }
class _AiButton extends StatelessWidget { const _AiButton({required this.compact}); final bool compact; @override Widget build(BuildContext c) => AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, width: compact ? 50 : 62, height: compact ? 50 : 62, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE1D9FF)]), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: _purple.withValues(alpha: .48), blurRadius: 23)]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome_rounded, color: _purple, size: 19), Text('AI', style: TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w900))])); }
class _Article { const _Article(this.title, this.category, this.time, this.author, this.gradient); final String title, category, time, author; final Gradient gradient; }
const _categories = ['✨ For You', 'Science', 'Math', 'Technology', 'Biology'];
const _heroes = [_Article('How does time actually work?', 'Physics', '7 min read', 'Sokha', LinearGradient(colors: [Color(0xFF395D85), Color(0xFF8C6DD9)])), _Article('Why plants are smarter than you think', 'Biology', '6 min read', 'Dara', LinearGradient(colors: [Color(0xFF2D766A), Color(0xFFB9C96A)])), _Article('How AI is changing education', 'Technology', '5 min read', 'Vichhean', LinearGradient(colors: [Color(0xFF7B4E96), Color(0xFFFF9C8A)]))];
const _trending = [_Article('CRISPR 101: Editing Life with Code', 'Science', '8 min', 'Sokha', LinearGradient(colors: [Color(0xFF355C7D), Color(0xFF6C5B7B)])), _Article('Is there life beyond Earth?', 'Space', '6 min', 'Dara', LinearGradient(colors: [Color(0xFF1C2541), Color(0xFF5BC0BE)])), _Article('How AI is changing education', 'Tech', '5 min', 'Vichhean', LinearGradient(colors: [Color(0xFF704C9B), Color(0xFFE987A6)]))];
const _latest = [_Article('The Role of Neurons in Human Brain', 'Neuroscience', '7 min read', 'Vichhean', LinearGradient(colors: [Color(0xFFE68D9A), Color(0xFFF3D190)])), _Article('Quantum Entanglement Explained in Simple Words', 'Physics', '6 min read', 'Sokha', LinearGradient(colors: [Color(0xFF425B9A), Color(0xFF8EA9DB)])), _Article('Why Plants Are Smarter Than You Think', 'Biology', '5 min read', 'Dara', LinearGradient(colors: [Color(0xFF3E826F), Color(0xFFC4D47B)]))];
