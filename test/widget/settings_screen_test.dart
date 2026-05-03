import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows two sliders labelled warning and danger', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Seuil avertissement'), findsOneWidget);
    expect(find.textContaining('Seuil danger'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
  });

  testWidgets('default labels show 1.0 m and 0.5 m', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.0 m'), findsOneWidget);
    expect(find.text('0.5 m'), findsOneWidget);
  });
}
