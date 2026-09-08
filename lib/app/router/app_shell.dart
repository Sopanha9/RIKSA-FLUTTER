import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';

import '../../core/widgets/riksa_bottom_navigation_bar.dart';
import '../../features/userProfile/presentation/widgets/riksa_profile_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Lets any screen inside the shell open the app-level drawer.
///
/// The drawer belongs to the shell's own Scaffold rather than to a tab's, so it
/// covers the floating bottom bar instead of being drawn under it. Screens
/// cannot reach that Scaffold with `Scaffold.of`, which finds their own, so the
/// opener is handed down here.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) => false;
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
      extendBody: true,
      drawer: const RiksaProfileDrawer(),
      // The Builder is what gives the opener a context below this Scaffold, so
      // `Scaffold.of` resolves to the shell rather than to a tab's own.
      body: Builder(
        builder: (context) => AppShellScope(
          openDrawer: Scaffold.of(context).openDrawer,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.navigationShell,
          ),
        ),
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
