import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
