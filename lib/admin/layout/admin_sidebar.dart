import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/admin_theme.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: isCollapsed ? 72 : 260,
      color: AdminTheme.sidebarBackground,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(color: AdminTheme.sidebarItemHover, height: 1),
          Expanded(child: _buildNavItems(currentPath, context)),
          const Divider(color: AdminTheme.sidebarItemHover, height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 20),
      alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
      child: isCollapsed
          ? const Icon(Icons.school, color: AdminTheme.sidebarTextPrimary, size: 28)
          : const Text(
              'Riksa Admin',
              style: TextStyle(
                color: AdminTheme.sidebarTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Widget _buildNavItems(String currentPath, BuildContext context) {
    final items = [
      _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/admin/dashboard'),
      _NavItem(icon: Icons.people_outline, label: 'Users', path: '/admin/users'),
      _NavItem(icon: Icons.menu_book_outlined, label: 'Lessons', path: '/admin/lessons'),
      _NavItem(icon: Icons.fitness_center_outlined, label: 'Exercises', path: '/admin/exercises'),
      _NavItem(icon: Icons.article_outlined, label: 'Blog Posts', path: '/admin/blog-posts'),
      _NavItem(icon: Icons.settings_outlined, label: 'Settings', path: '/admin/settings'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) {
        final isActive = currentPath == item.path;

        return Tooltip(
          message: isCollapsed ? item.label : '',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (currentPath != item.path) {
                  context.go(item.path);
                }
              },
              hoverColor: AdminTheme.sidebarItemHover.withAlpha(80),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 0 : 20,
                  vertical: 12,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AdminTheme.sidebarItemActive
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isCollapsed
                    ? Center(
                        child: Icon(
                          item.icon,
                          color: isActive
                              ? Colors.white
                              : AdminTheme.sidebarTextMuted,
                          size: 22,
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isActive
                                ? Colors.white
                                : AdminTheme.sidebarTextMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AdminTheme.sidebarTextMuted,
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: AdminTheme.sidebarItemHover.withAlpha(80),
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 20),
          child: isCollapsed
              ? const Center(
                  child: Icon(Icons.logout, color: AdminTheme.sidebarTextMuted, size: 22),
                )
              : const Row(
                  children: [
                    Icon(Icons.logout, color: AdminTheme.sidebarTextMuted, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(color: AdminTheme.sidebarTextMuted, fontSize: 14),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}
