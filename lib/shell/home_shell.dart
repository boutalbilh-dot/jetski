import 'package:flutter/material.dart';
import '../features/depth/depth_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import 'connection_indicator.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _screens = const [DepthScreen(), MapScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _screens[_index]),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: const SafeArea(
              top: false,
              child: ConnectionIndicator(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water), label: 'Profondeur'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Carte'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }
}
