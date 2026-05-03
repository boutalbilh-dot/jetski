import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/app_providers.dart';

void main() {
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(alertNotifierProvider);
    return const JetskiApp();
  }
}
