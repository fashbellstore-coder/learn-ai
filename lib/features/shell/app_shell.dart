import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/theme_extras.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) return navigationShell;
          return Row(
            children: [
              NavigationRail(
                backgroundColor: palette.card,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.6,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.accent,
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book_rounded),
                    label: Text('Learn'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bolt_outlined),
                    selectedIcon: Icon(Icons.bolt_rounded),
                    label: Text('Practice'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.handyman_outlined),
                    selectedIcon: Icon(Icons.handyman_rounded),
                    label: Text('Projects'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Profile'),
                  ),
                ],
              ),
              Expanded(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(
                      constraints.maxWidth - 80,
                      constraints.maxHeight,
                    ),
                  ),
                  child: navigationShell,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 900
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                border: Border(
                  top: BorderSide(color: palette.border.withValues(alpha: 0.5)),
                ),
              ),
              child: SafeArea(
                child: NavigationBar(
                  height: 76,
                  backgroundColor: Colors.transparent,
                  indicatorColor: palette.accent.withValues(alpha: 0.16),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (i) => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: AppStrings.navHome,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: AppStrings.navLearn,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bolt_outlined),
                      selectedIcon: Icon(Icons.bolt_rounded),
                      label: AppStrings.navPractice,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.handyman_outlined),
                      selectedIcon: Icon(Icons.handyman_rounded),
                      label: AppStrings.navProjects,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: AppStrings.navProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
