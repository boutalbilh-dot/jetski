import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/alert_engine.dart';
import 'depth_display.dart';

class DepthScreen extends ConsumerWidget {
  const DepthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depth = ref.watch(depthStreamProvider).valueOrNull;
    final level = ref.watch(alertLevelProvider).valueOrNull ?? AlertLevel.safe;
    final unit = ref.watch(unitProvider);
    return Scaffold(
      body: SafeArea(
        child: DepthDisplay(depth: depth, level: level, unit: unit),
      ),
    );
  }
}
