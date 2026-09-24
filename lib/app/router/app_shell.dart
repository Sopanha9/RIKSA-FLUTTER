import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/riksa_bottom_navigation_bar.dart';
import '../../features/mascot/presentation/widgets/floating_buddy.dart';
import '../../features/userProfile/presentation/widgets/riksa_profile_drawer.dart';

/// How many screens the tab the learner is standing in has stacked up.
///
/// One at a tab root, more as soon as anything is pushed on top of it. The
/// count comes from the router's own match list rather than from the live
/// navigators, so it is already correct in the frame the shell rebuilds in —
/// asking a [NavigatorState] would answer for the stack the pop animation has
/// not finished unwinding yet.
int branchStackDepth(RouteMatchList configuration) {
  var matches = configuration.matches;
  // Descend past the shells to the branch holding the screens themselves.
  for (
    var shells = matches.whereType<ShellRouteMatch>();
    shells.isNotEmpty;
    shells = matches.whereType<ShellRouteMatch>()
  ) {
    matches = shells.last.matches;
  }
  return matches.where(_buildsAScreen).length;
}

/// A route that only groups or redirects contributes no screen to the stack.
bool _buildsAScreen(RouteMatchBase match) {
  final route = match.route;
  if (route is! GoRoute) return true;
  return route.builder != null || route.pageBuilder != null;
}

/// Whether the floating tab bar belongs over a tab holding [branchStackDepth]
/// screens.
///
/// A tab is a destination, not a step. The bar belongs on the screen a tab
/// lands on and nowhere the learner had to travel to reach: every screen pushed
/// on top of a tab root already draws a back control — an explicit one, or the
/// leading arrow an `AppBar` implies — so it is exactly the screen that has its
/// own way out and does not need the tabs.
///
/// Reading the stack instead of the path is also what keeps this honest as
/// routes are added. A lesson, a chat, a composer and the settings forms each
/// carry a bottom bar or a keyboard of their own, and a list of paths to
/// exclude only stays right for as long as someone remembers to extend it.
bool showsBottomNavigation(int branchStackDepth) => branchStackDepth <= 1;

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
  bool _showNavBar = true;

  Widget _floatingBuddyOverlay() {
    try {
      ProviderScope.containerOf(context, listen: false);
      return const FloatingBuddy();
    } on StateError {
      // AppShell is also used alone in router tests, outside the app's scope.
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return Scaffold(
      key: const ValueKey('main-app-shell'),
      extendBody: true,
      drawer: const RiksaProfileDrawer(),
      // The Builder is what gives the opener a context below this Scaffold, so
      // `Scaffold.of` resolves to the shell rather than to a tab's own.
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_showNavBar) setState(() => _showNavBar = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_showNavBar) setState(() => _showNavBar = true);
          }
          return false;
        },
        child: Builder(
          builder: (context) => AppShellScope(
            openDrawer: Scaffold.of(context).openDrawer,
            child: Stack(
              fit: StackFit.expand,
              children: [widget.navigationShell, _floatingBuddyOverlay()],
            ),
          ),
        ),
      ),
      // The shell builder does not run again for a push inside a branch, so
      // the delegate supplies the rebuild, and its configuration carries the
      // pushed route the shell has to answer for.
      bottomNavigationBar: ListenableBuilder(
        listenable: router.routerDelegate,
        builder: (context, _) {
          final depth = branchStackDepth(
            router.routerDelegate.currentConfiguration,
          );
          if (!showsBottomNavigation(depth)) return const SizedBox.shrink();
          return RiksaBottomNavigationBar(
            key: const ValueKey('persistent-bottom-navigation'),
            currentIndex: widget.navigationShell.currentIndex,
            isExpanded: _showNavBar,
            onExpand: () => setState(() => _showNavBar = true),
            onSelected: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          );
        },
      ),
    );
  }
}
