import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/theme/app_theme.dart';
import 'package:projet_jetski/features/depth/depth_display.dart';
import 'package:projet_jetski/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets(
      'DepthDisplay shows depth in metres with safe color when level is safe',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const DepthDisplay(depth: 3.2, level: AlertLevel.safe)));
    expect(find.text('3.2'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    final container = tester.widget<Container>(
      find.byKey(const Key('depth-bg')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTheme.safeColor);
  });

  testWidgets('shows danger color when level is danger', (tester) async {
    await tester.pumpWidget(
        _wrap(const DepthDisplay(depth: 0.3, level: AlertLevel.danger)));
    final container = tester.widget<Container>(
      find.byKey(const Key('depth-bg')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTheme.dangerColor);
  });

  testWidgets('shows --.- when depth is null', (tester) async {
    await tester.pumpWidget(
        _wrap(const DepthDisplay(depth: null, level: AlertLevel.safe)));
    expect(find.text('--.-'), findsOneWidget);
  });

  testWidgets('renders feet when unit is feet (3.28 m -> 10.8 ft)',
      (tester) async {
    await tester.pumpWidget(_wrap(const DepthDisplay(
      depth: 3.28,
      level: AlertLevel.safe,
      unit: DepthUnit.feet,
    )));
    expect(find.text('10.8'), findsOneWidget);
    expect(find.text('ft'), findsOneWidget);
    expect(find.text('m'), findsNothing);
  });
}
