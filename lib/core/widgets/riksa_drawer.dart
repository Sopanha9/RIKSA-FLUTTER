import 'package:flutter/material.dart';

const _purple = Color(0xFF7C5CFF);

class RiksaDrawer extends StatefulWidget {
  const RiksaDrawer({
    required this.dark,
    required this.fullName,
    required this.username,
    required this.onLogout,
    super.key,
  });

  final bool dark;
  final String fullName;
  final String username;
  final Future<void> Function() onLogout;

  @override
  State<RiksaDrawer> createState() => _RiksaDrawerState();
}

class _RiksaDrawerState extends State<RiksaDrawer> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final surface = dark ? const Color(0xFF151821) : const Color(0xFFFCFBFF);
    final text = dark ? const Color(0xFFF5F5F7) : const Color(0xFF17171C);
    final muted = dark ? const Color(0xFF9499A6) : const Color(0xFF92959D);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
        child: Container(
          color: surface,
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Column(
                children: [
                  _ProfileCard(dark: dark, fullName: widget.fullName, username: widget.username, text: text, muted: muted),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MenuSection(label: 'GENERAL', dark: dark, text: text, muted: muted, selectedIndex: _selectedIndex, startIndex: 0, onSelected: _select, items: const [
                            _DrawerItem(Icons.trending_up_rounded, 'Popular'),
                            _DrawerItem(Icons.newspaper_rounded, 'Latest News'),
                            _DrawerItem(Icons.favorite_border_rounded, 'Favorites'),
                          ]),
                          _MenuSection(label: 'ABOUT', dark: dark, text: text, muted: muted, selectedIndex: _selectedIndex, startIndex: 3, onSelected: _select, items: const [
                            _DrawerItem(Icons.auto_awesome_rounded, 'RIKSA'),
                            _DrawerItem(Icons.privacy_tip_outlined, 'Privacy Policy'),
                            _DrawerItem(Icons.description_outlined, 'User Agreement'),
                          ]),
                          _MenuSection(label: 'SETTINGS', dark: dark, text: text, muted: muted, selectedIndex: _selectedIndex, startIndex: 6, onSelected: _select, items: const [
                            _DrawerItem(Icons.admin_panel_settings_outlined, 'Privacy Center'),
                            _DrawerItem(Icons.language_rounded, 'App Language'),
                          ]),
                          _MenuSection(label: 'HELP & SUPPORT', dark: dark, text: text, muted: muted, selectedIndex: _selectedIndex, startIndex: 8, onSelected: _select, items: const [
                            _DrawerItem(Icons.support_agent_rounded, 'Support Center'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LogoutButton(onTap: widget.onLogout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.dark, required this.fullName, required this.username, required this.text, required this.muted});
  final bool dark;
  final String fullName, username;
  final Color text, muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: dark
          ? const LinearGradient(colors: [Color(0xFF26213C), Color(0xFF1D2030)])
          : const LinearGradient(colors: [Color(0xFFF0EBFF), Color(0xFFFFEDF5)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _purple.withValues(alpha: dark ? .32 : .18)),
      boxShadow: [BoxShadow(color: _purple.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _purple),
            child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFFFFD5BB), child: Icon(Icons.face_rounded, color: text, size: 38)),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF53C788),
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? const Color(0xFF1D2030) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text('@$username', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _Stat(value: '23', label: 'Following', text: text, muted: muted),
        Container(width: 1, height: 31, color: muted.withValues(alpha: .24)),
        _Stat(value: '23', label: 'Followers', text: text, muted: muted),
      ]),
    ]),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.text, required this.muted});
  final String value, label;
  final Color text, muted;
  @override Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 2), Text(label, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))]));
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.label, required this.items, required this.startIndex, required this.selectedIndex, required this.onSelected, required this.dark, required this.text, required this.muted});
  final String label;
  final List<_DrawerItem> items;
  final int startIndex, selectedIndex;
  final ValueChanged<int> onSelected;
  final bool dark;
  final Color text, muted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.05)),
      const SizedBox(height: 10),
      ...List.generate(items.length, (offset) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: _MenuRow(item: items[offset], active: selectedIndex == startIndex + offset, dark: dark, text: text, muted: muted, onTap: () => onSelected(startIndex + offset)),
      )),
    ]),
  );
}

class _DrawerItem { const _DrawerItem(this.icon, this.label); final IconData icon; final String label; }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.active, required this.dark, required this.text, required this.muted, required this.onTap});
  final _DrawerItem item;
  final bool active, dark;
  final Color text, muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: active ? _purple.withValues(alpha: dark ? .18 : .08) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _purple.withValues(alpha: dark ? .20 : .12), borderRadius: BorderRadius.circular(11)), child: Icon(item.icon, color: _purple, size: 19)),
          const SizedBox(width: 12),
          Expanded(child: Text(item.label, style: TextStyle(color: active ? _purple : text, fontWeight: active ? FontWeight.w800 : FontWeight.w700, fontSize: 14))),
          Icon(Icons.chevron_right_rounded, color: muted, size: 20),
        ]),
      ),
    ),
  );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final Future<void> Function() onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFF5E78).withValues(alpha: .07), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFF5E78).withValues(alpha: .20))),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: Color(0xFFFF5E78), size: 20), SizedBox(width: 9), Text('Log out', style: TextStyle(color: Color(0xFFFF5E78), fontWeight: FontWeight.w800))]),
      ),
    ),
  );
}
