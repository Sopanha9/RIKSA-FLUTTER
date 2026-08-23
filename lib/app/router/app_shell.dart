import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';

import '../../core/widgets/riksa_bottom_navigation_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _bottomNavigationCollapsed = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _setBottomNavigationCollapsed(true);
          break;
        case ScrollDirection.forward:
          _setBottomNavigationCollapsed(false);
          break;
        case ScrollDirection.idle:
          break;
      }
    } else if (notification.metrics.pixels <= 0) {
      _setBottomNavigationCollapsed(false);
    }
    return false;
  }

  void _setBottomNavigationCollapsed(bool collapsed) {
    if (_bottomNavigationCollapsed == collapsed || !mounted) return;
    setState(() => _bottomNavigationCollapsed = collapsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('main-app-shell'),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: RiksaBottomNavigationBar(
        key: const ValueKey('persistent-bottom-navigation'),
        currentIndex: widget.navigationShell.currentIndex,
        collapsed: _bottomNavigationCollapsed,
        onSelected: (index) {
          _setBottomNavigationCollapsed(false);
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        onCollapsedTap: () {
          _setBottomNavigationCollapsed(false);
          widget.navigationShell.goBranch(0);
        },
      ),
    );
  }
}
