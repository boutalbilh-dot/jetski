import 'package:flutter/material.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/alert_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

const double _metersPerFoot = 0.3048;

// Pre-computed const decorations indexed by alert level — saves a heap
// allocation per build at the depth-stream rebuild rate (5–10 Hz).
const Map<AlertLevel, BoxDecoration> _decorationsByLevel = {
  AlertLevel.safe: BoxDecoration(color: AppTheme.safeColor),
  AlertLevel.warning: BoxDecoration(color: AppTheme.warningColor),
  AlertLevel.danger: BoxDecoration(color: AppTheme.dangerColor),
};

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
    final bg = _decorationsByLevel[level]!;
    final unitLabel = unit == DepthUnit.feet ? 'ft' : 'm';
    final String text;
    if (depth == null) {
      text = '--.-';
    } else {
      final value = unit == DepthUnit.feet ? depth! / _metersPerFoot : depth!;
      text = value.toStringAsFixed(1);
    }
    final l10n = AppLocalizations.of(context)!;
    return RepaintBoundary(
      child: Container(
        key: const Key('depth-bg'),
        decoration: bg,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.depthLabel,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, letterSpacing: 2)),
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
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 28)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
