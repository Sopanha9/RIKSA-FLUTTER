import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _purple = Color(0xFF7C5CFF);

/// Example article-detail experience. Replace the local values with API data
/// when the Blog backend and detail model are introduced.
class BlogDetailsScreen extends StatefulWidget {
  const BlogDetailsScreen({super.key});
  @override State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  final _controller = ScrollController();
  var _progress = 0.0;
  var _summaryOpen = true;
  var _liked = false;
  var _bookmarked = false;

  @override
  void initState() { super.initState(); _controller.addListener(_updateProgress); }
  void _updateProgress() { final max = _controller.position.maxScrollExtent; setState(() => _progress = max == 0 ? 0 : (_controller.offset / max).clamp(0.0, 1.0)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF17171C);
    const muted = Color(0xFF777B86);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      body: Stack(children: [
        CustomScrollView(controller: _controller, slivers: [
          SliverToBoxAdapter(child: _ArticleHero(bookmarked: _bookmarked, onBack: () => context.pop(), onBookmark: () => setState(() => _bookmarked = !_bookmarked))),
          SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -28), child: Container(decoration: const BoxDecoration(color: Color(0xFFFCFBFF), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: Padding(padding: const EdgeInsets.fromLTRB(20, 27, 20, 130), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AuthorCard(text: text, muted: muted),
            const SizedBox(height: 22),
            _AiSummary(open: _summaryOpen, onTap: () => setState(() => _summaryOpen = !_summaryOpen)),
            const SizedBox(height: 31),
            _Paragraph(dropCap: 'E', text: 'Every living thing on Earth carries an extraordinary set of instructions. That instruction manual is DNA — a molecule so compact that it fits inside nearly every cell, yet detailed enough to guide the growth and function of an entire organism.', textColor: text),
            const SizedBox(height: 22),
            _Paragraph(text: 'DNA does not act alone. It works with proteins and cellular machinery to turn genetic information into the traits we can see, from eye colour to the way a plant responds to sunlight.', textColor: text),
            const SizedBox(height: 35),
            _Heading('The building blocks of life', text),
            const SizedBox(height: 14),
            _Paragraph(text: 'The DNA molecule is built from four chemical letters: A, T, C and G. Their order forms a code, and different sections of that code are called genes. Genes provide the recipes for making proteins.', textColor: text),
            const SizedBox(height: 22),
            Container(height: 190, decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), gradient: const LinearGradient(colors: [Color(0xFFCBE5EA), Color(0xFFB4A6FF), Color(0xFFFFD0AB)])), child: const Center(child: Icon(Icons.biotech_rounded, color: Colors.white, size: 68))),
            const SizedBox(height: 8),
            Text('A simplified view of the molecular code inside every cell.', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _purple.withValues(alpha: .09), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('“', style: TextStyle(color: _purple, fontSize: 38, fontWeight: FontWeight.w900, height: .7)), const SizedBox(height: 8), Text('DNA is essentially the instruction manual of life.', style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w800, height: 1.35))])),
            const SizedBox(height: 30),
            _Heading('Why it matters', text),
            const SizedBox(height: 14),
            _Paragraph(text: 'Understanding DNA helps us explore inherited conditions, develop medicines and make sense of the incredible diversity of life. The code is ancient, but every new discovery gives us another way to read it.', textColor: text),
          ]))))))),
        ]),
        Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(value: _progress, minHeight: 4, color: _purple, backgroundColor: Colors.white.withValues(alpha: .22))),
        Align(alignment: Alignment.bottomCenter, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _ActionBar(liked: _liked, onLike: () => setState(() => _liked = !_liked))))),
      ]),
    );
  }
}

class _ArticleHero extends StatelessWidget { const _ArticleHero({required this.bookmarked, required this.onBack, required this.onBookmark}); final bool bookmarked; final VoidCallback onBack, onBookmark; @override Widget build(BuildContext c) => SizedBox(height: MediaQuery.sizeOf(c).height * .52, child: DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF53775F), Color(0xFFB2C66B), Color(0xFF20291A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: Stack(children: [Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .04), Colors.black.withValues(alpha: .16), Colors.black.withValues(alpha: .84)])))), SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [_GlassIcon(icon: Icons.arrow_back_rounded, onTap: onBack), Row(children: [_GlassIcon(icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, onTap: onBookmark), const SizedBox(width: 9), const _GlassIcon(icon: Icons.more_horiz_rounded)])]))), Positioned(left: 24, right: 24, bottom: 43, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .20), borderRadius: BorderRadius.circular(14)), child: const Text('BIOLOGY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))), const SizedBox(height: 13), const Text('How DNA\nactually works', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 38, height: 1.05)), const SizedBox(height: 9), Text('Understanding the code that makes us who we are.', style: TextStyle(color: Colors.white.withValues(alpha: .86), fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 16), Row(children: [const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFFD5BB), child: Icon(Icons.face_rounded, color: _purple)), const SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Spencer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text('Jul 13, 2026 • 7 min read', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 11, fontWeight: FontWeight.w600))])])]))]))); }
class _GlassIcon extends StatelessWidget { const _GlassIcon({required this.icon, this.onTap}); final IconData icon; final VoidCallback? onTap; @override Widget build(BuildContext c) => ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Material(color: Colors.black.withValues(alpha: .22), child: InkWell(onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white)))))); }
class _AuthorCard extends StatelessWidget { const _AuthorCard({required this.text, required this.muted}); final Color text, muted; @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 16)]), child: Row(children: [const CircleAvatar(radius: 27, backgroundColor: Color(0xFFFFD5BB), child: Icon(Icons.face_rounded, color: _purple, size: 33)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Spencer', style: TextStyle(color: text, fontWeight: FontWeight.w900)), Text('@spencer • Science writer', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)), Text('12 articles', style: TextStyle(color: muted, fontSize: 11))])), Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(color: _purple.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: const Text('Follow', style: TextStyle(color: _purple, fontWeight: FontWeight.w800)))])); }
class _AiSummary extends StatelessWidget { const _AiSummary({required this.open, required this.onTap}); final bool open; final VoidCallback onTap; @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF1ECFF), Color(0xFFFFEEF5)]), borderRadius: BorderRadius.circular(22), border: Border.all(color: _purple.withValues(alpha: .15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [InkWell(onTap: onTap, child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: _purple), const SizedBox(width: 8), const Expanded(child: Text('AI Quick Summary', style: TextStyle(fontWeight: FontWeight.w900))), Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _purple)])), AnimatedSize(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, child: open ? const Padding(padding: EdgeInsets.only(top: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('• DNA stores genetic information.'), SizedBox(height: 5), Text('• DNA is made from A, T, C and G.'), SizedBox(height: 5), Text('• Genes help control our traits.'), SizedBox(height: 12), Text('Ask AI about this ✨ →', style: TextStyle(color: _purple, fontWeight: FontWeight.w800))])) : const Padding(padding: EdgeInsets.only(top: 8), child: Text('Get the key takeaways from this article.')))])); }
class _Heading extends StatelessWidget { const _Heading(this.label, this.color); final String label; final Color color; @override Widget build(BuildContext c) => Row(children: [Container(width: 4, height: 27, decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 10), Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 25))) ]); }
class _Paragraph extends StatelessWidget { const _Paragraph({required this.text, required this.textColor, this.dropCap}); final String text; final Color textColor; final String? dropCap; @override Widget build(BuildContext c) => RichText(text: TextSpan(style: TextStyle(color: textColor, fontSize: 17, height: 1.65), children: [if (dropCap != null) WidgetSpan(alignment: PlaceholderAlignment.top, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: _purple.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text(dropCap!, style: const TextStyle(color: _purple, fontSize: 29, fontWeight: FontWeight.w900)))), TextSpan(text: text)])); }
class _ActionBar extends StatelessWidget { const _ActionBar({required this.liked, required this.onLike}); final bool liked; final VoidCallback onLike; @override Widget build(BuildContext c) => ClipRRect(borderRadius: BorderRadius.circular(34), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: Container(height: 76, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .86), borderRadius: BorderRadius.circular(34), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .11), blurRadius: 22)]), child: Row(children: [InkWell(onTap: onLike, child: Row(children: [Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? const Color(0xFFFF627E) : const Color(0xFF555966)), const SizedBox(width: 5), const Text('105')])), const SizedBox(width: 19), const Row(children: [Icon(Icons.chat_bubble_outline_rounded, size: 19), SizedBox(width: 5), Text('10')]), const Spacer(), const Icon(Icons.auto_awesome_rounded, color: _purple, size: 18), const SizedBox(width: 5), const Text('Explain', style: TextStyle(color: _purple, fontWeight: FontWeight.w900)), const SizedBox(width: 14), const Icon(Icons.ios_share_rounded, color: Color(0xFF555966))])))); }
