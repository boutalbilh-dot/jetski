import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: _BootstrapApp()));
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Projet Jetski — bootstrap'))),
    );
  }
}
