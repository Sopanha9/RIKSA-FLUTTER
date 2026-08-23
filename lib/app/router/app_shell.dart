import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/riksa_bottom_navigation_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('main-app-shell'),
      body: navigationShell,
      bottomNavigationBar: RiksaBottomNavigationBar(
        key: const ValueKey('persistent-bottom-navigation'),
        currentIndex: navigationShell.currentIndex,
        collapsed: false,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onCollapsedTap: () => navigationShell.goBranch(0),
      ),
    );
  }
}
