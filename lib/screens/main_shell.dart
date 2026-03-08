import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Root shell that hosts the persistent BottomNavigationBar.
/// Each tab preserves its own navigation stack via [IndexedStack].
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    SosScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.sos_outlined),
      selectedIcon: Icon(Icons.sos),
      label: 'SOS',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
        // Highlight the SOS tab in red regardless of theme
        indicatorColor: _currentIndex == 1
            ? Theme.of(context).colorScheme.error.withAlpha(30)
            : null,
      ),
    );
  }
}
