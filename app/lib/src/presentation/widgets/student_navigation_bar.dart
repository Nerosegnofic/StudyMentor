import 'package:flutter/material.dart';

class StudentNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const StudentNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10)),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.store_outlined),
          selectedIcon: Icon(Icons.store),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Leaderboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Friends',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
