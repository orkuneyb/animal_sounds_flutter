import 'package:animal_sounds_flutter/pages/tabs/animals_tab.dart';
import 'package:animal_sounds_flutter/pages/tabs/explore_tab.dart';
import 'package:animal_sounds_flutter/pages/tabs/games_tab.dart';
import 'package:animal_sounds_flutter/pages/tabs/profile_tab.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Root navigation scaffold with a Material 3 [NavigationBar] and four tabs.
///
/// Uses [IndexedStack] to preserve each tab's state when switching between them.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    AnimalsTab(),
    ExploreTab(),
    GamesTab(),
    ProfileTab(),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        elevation: 2,
        height: 68,
        backgroundColor: AppColors.surfaceContainerLow,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.pets_outlined),
            selectedIcon: const Icon(Icons.pets, color: AppColors.primaryDark),
            label: 'tab_animals'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon:
                const Icon(Icons.explore, color: AppColors.primaryDark),
            label: 'tab_explore'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon:
                const Icon(Icons.sports_esports, color: AppColors.primaryDark),
            label: 'tab_games'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon:
                const Icon(Icons.person, color: AppColors.primaryDark),
            label: 'tab_profile'.tr(),
          ),
        ],
      ),
    );
  }
}
