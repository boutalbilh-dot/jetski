import 'package:flutter/material.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/alert_engine.dart';
import '../../core/theme/app_theme.dart';

const double _metersPerFoot = 0.3048;

class DepthDisplay extends StatelessWidget {
  final double? depth;
  final AlertLevel level;
  final DepthUnit unit;

  const DepthDisplay({
    super.key,
    required this.depth,
    required this.level,
    this.unit = DepthUnit.meters,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.colorForLevel(level);
    final unitLabel = unit == DepthUnit.feet ? 'ft' : 'm';
    final String text;
    if (depth == null) {
      text = '--.-';
    } else {
      final value = unit == DepthUnit.feet ? depth! / _metersPerFoot : depth!;
      text = value.toStringAsFixed(1);
    }
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
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0, left: 8),
                child: Text(unitLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 28)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
