enum AlertLevel { safe, warning, danger }

typedef AlertTransitionCallback = void Function(AlertLevel newLevel);

class AlertEngine {
  final double warningMeters;
  final double dangerMeters;
  final double hysteresisMeters;
  AlertLevel _level = AlertLevel.safe;
  AlertTransitionCallback? onTransition;

  AlertEngine({
    required this.warningMeters,
    required this.dangerMeters,
    this.hysteresisMeters = 0.3,
  }) : assert(dangerMeters < warningMeters);

  AlertLevel get level => _level;

  /// Feed a new depth reading and return the resulting level.
  AlertLevel update(double depthMeters) {
    final next = _compute(depthMeters);
    if (next != _level) {
      _level = next;
      onTransition?.call(next);
    }
    return _level;
  }

  AlertLevel _compute(double d) {
    switch (_level) {
      case AlertLevel.safe:
        if (d <= dangerMeters) return AlertLevel.danger;
        if (d <= warningMeters) return AlertLevel.warning;
        return AlertLevel.safe;
      case AlertLevel.warning:
        if (d <= dangerMeters) return AlertLevel.danger;
        if (d > warningMeters + hysteresisMeters) return AlertLevel.safe;
        return AlertLevel.warning;
      case AlertLevel.danger:
        if (d > dangerMeters + hysteresisMeters) {
          // Step back up — could be still in warning band, or fully safe.
          if (d > warningMeters + hysteresisMeters) return AlertLevel.safe;
          return AlertLevel.warning;
        }
        return AlertLevel.danger;
    }
  }
}
