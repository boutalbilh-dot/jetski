import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shell/home_shell.dart';

class JetskiApp extends StatelessWidget {
  const JetskiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Jetski',
      theme: AppTheme.light(),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
