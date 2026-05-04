import 'package:flutter/material.dart';
import '../features/depth/depth_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack keeps each screen's element tree alive across tab
          // switches — the map keeps its camera state and the depth display
          // keeps its stream subscription warm.
          Positioned.fill(child: IndexedStack(index: _index, children: _screens)),
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
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.water), label: l10n.navDepth),
          NavigationDestination(
              icon: const Icon(Icons.map), label: l10n.navMap),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: l10n.navSettings),
        ],
      ),
    );
  }
}
