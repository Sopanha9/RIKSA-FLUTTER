import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key, required this.child});

  final Widget child;

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _sidebarCollapsed = false;

  static const double _breakpoint = 900;

  @override
  void initState() {
    super.initState();
    _updateCollapseState();
  }

  void _updateCollapseState() {
    final width = MediaQuery.of(context).size.width;
    if (width < _breakpoint && !_sidebarCollapsed) {
      setState(() => _sidebarCollapsed = true);
    } else if (width >= _breakpoint && _sidebarCollapsed) {
      setState(() => _sidebarCollapsed = false);
    }
  }

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  String _currentTitle() {
    final path = GoRouterState.of(context).matchedLocation;
    const titles = {
      '/admin/dashboard': 'Dashboard',
      '/admin/users': 'Users',
      '/admin/lessons': 'Lessons',
      '/admin/exercises': 'Exercises',
      '/admin/blog-posts': 'Blog Posts',
      '/admin/settings': 'Settings',
    };
    return titles[path] ?? 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateCollapseState();
        });

        return Scaffold(
          body: Row(
            children: [
              AdminSidebar(isCollapsed: _sidebarCollapsed),
              Expanded(
                child: Column(
                  children: [
                    AdminTopbar(
                      onToggleSidebar: _toggleSidebar,
                      title: _currentTitle(),
                    ),
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
