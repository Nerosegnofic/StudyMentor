import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10)),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: loc.navHomeLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.store_outlined),
          selectedIcon: const Icon(Icons.store),
          label: loc.navShopLabel,
        ),
      ],
    );
  }
}
