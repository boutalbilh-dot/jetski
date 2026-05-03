import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/features/settings/settings_screen.dart';
import 'package:projet_jetski/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaterialApp _wrap({required Locale locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('French locale', () {
    testWidgets('shows two threshold sliders with default labels',
        (tester) async {
      await tester
          .pumpWidget(ProviderScope(child: _wrap(locale: const Locale('fr'))));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.text('1.0 m'), findsOneWidget);
      expect(find.text('0.5 m'), findsOneWidget);
    });

    testWidgets('shows simulation panel + scenario picker', (tester) async {
      await tester
          .pumpWidget(ProviderScope(child: _wrap(locale: const Locale('fr'))));
      await tester.pumpAndSettle();
      expect(find.text('Mode simulation'), findsOneWidget);
      expect(find.text('Scénario :'), findsOneWidget);
    });

    testWidgets('shows units toggle with French labels', (tester) async {
      await tester
          .pumpWidget(ProviderScope(child: _wrap(locale: const Locale('fr'))));
      await tester.pumpAndSettle();
      expect(find.text('Mètres'), findsOneWidget);
      expect(find.text('Pieds'), findsOneWidget);
    });

    testWidgets('Bluetooth panel hidden in default (sim) mode',
        (tester) async {
      await tester
          .pumpWidget(ProviderScope(child: _wrap(locale: const Locale('fr'))));
      await tester.pumpAndSettle();
      expect(find.text('Sondeur Bluetooth'), findsNothing);
      expect(find.text('Sondeur WiFi (NMEA UDP)'), findsNothing);
    });
  });

  group('English locale', () {
    testWidgets('shows English labels', (tester) async {
      await tester
          .pumpWidget(ProviderScope(child: _wrap(locale: const Locale('en'))));
      await tester.pumpAndSettle();
      expect(find.text('Warning threshold'), findsOneWidget);
      expect(find.text('Danger threshold'), findsOneWidget);
      expect(find.text('Simulation mode'), findsOneWidget);
      expect(find.text('Meters'), findsOneWidget);
      expect(find.text('Feet'), findsOneWidget);
    });
  });
}
