import 'package:flutter/material.dart';
import '../../core/services/alert_engine.dart';
import '../../core/theme/app_theme.dart';

class DepthDisplay extends StatelessWidget {
  final double? depth;
  final AlertLevel level;

  const DepthDisplay({super.key, required this.depth, required this.level});

  @override
  Widget build(BuildContext context) {
    final bg = switch (level) {
      AlertLevel.safe => AppTheme.safeColor,
      AlertLevel.warning => AppTheme.warningColor,
      AlertLevel.danger => AppTheme.dangerColor,
    };
    final text = depth == null ? '--.-' : depth!.toStringAsFixed(1);
    return Container(
      key: const Key('depth-bg'),
      decoration: BoxDecoration(color: bg),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profondeur',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const Padding(
                padding: EdgeInsets.only(bottom: 18.0, left: 8),
                child: Text('m',
                    style: TextStyle(color: Colors.white70, fontSize: 28)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
