import 'package:flutter/material.dart';

const _purple = Color(0xFF7C5CFF);

/// Shared top controls for primary RIKSA screens.
class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.dark,
    required this.compact,
    required this.onMenu,
    required this.onTheme,
    super.key,
  });

  final bool dark;
  final bool compact;
  final VoidCallback onMenu;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    height: compact ? 42 : 54,
    child: Row(children: [
      Material(color: dark ? const Color(0xFF20242E) : Colors.white, shape: const CircleBorder(), child: InkWell(onTap: onMenu, customBorder: const CircleBorder(), child: SizedBox(width: 52, height: 52, child: Icon(Icons.menu_rounded, color: dark ? Colors.white : const Color(0xFF41444B), size: 27)))),
      const Spacer(),
      GestureDetector(onTap: onTheme, child: Container(width: 104, height: 52, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: dark ? const Color(0xFF20242E) : const Color(0xFFF0F0F4), borderRadius: BorderRadius.circular(30)), child: Stack(children: [AnimatedAlign(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic, alignment: dark ? Alignment.centerLeft : Alignment.centerRight, child: const CircleAvatar(radius: 22, backgroundColor: Color(0xFFFCFCFF))), Align(alignment: Alignment.centerLeft, child: Icon(Icons.nightlight_round, color: dark ? _purple : const Color(0xFF92959D))), const Align(alignment: Alignment.centerRight, child: Icon(Icons.light_mode_rounded, color: Color(0xFFFFAB00)))]))),
      const SizedBox(width: 12),
      const _CreateButton(),
    ]),
  );
}

class _CreateButton extends StatefulWidget {
  const _CreateButton();
  @override State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  var _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    child: AnimatedRotation(duration: const Duration(milliseconds: 180), turns: _down ? .125 : 0, child: AnimatedScale(duration: const Duration(milliseconds: 180), scale: _down ? .92 : 1, child: Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFB9AAFF), _purple]), boxShadow: [BoxShadow(color: _purple.withValues(alpha: .28), blurRadius: 18)]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 31)))),
  );
}
