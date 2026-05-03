import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows two threshold sliders with default labels', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.text('1.0 m'), findsOneWidget);
    expect(find.text('0.5 m'), findsOneWidget);
  });

  testWidgets('shows simulation status and scenario picker', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Mode simulation'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('shows units toggle (m / ft)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Mètres'), findsOneWidget);
    expect(find.text('Pieds'), findsOneWidget);
  });
}
