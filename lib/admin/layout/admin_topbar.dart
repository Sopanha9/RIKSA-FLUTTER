import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({
    super.key,
    this.onToggleSidebar,
    required this.title,
  });

  final VoidCallback? onToggleSidebar;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onToggleSidebar,
        icon: const Icon(Icons.menu, size: 22),
        tooltip: 'Toggle sidebar',
      ),
      title: Text(title),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, size: 22),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 16,
          backgroundColor: AdminTheme.sidebarItemActive,
          child: const Icon(Icons.person, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
