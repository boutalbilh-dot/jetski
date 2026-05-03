enum AlertLevel { safe, warning, danger }

typedef AlertTransitionCallback = void Function(AlertLevel newLevel);

class AlertEngine {
  double _warning;
  double _danger;
  final double hysteresisMeters;
  AlertLevel _level = AlertLevel.safe;
  AlertTransitionCallback? onTransition;

  AlertEngine({
    required double warningMeters,
    required double dangerMeters,
    this.hysteresisMeters = 0.3,
  })  : _warning = warningMeters,
        _danger = dangerMeters,
        assert(dangerMeters < warningMeters);

  double get warningMeters => _warning;
  double get dangerMeters => _danger;
  AlertLevel get level => _level;

  /// Update thresholds without resetting hysteresis state. Lets a long-lived
  /// engine survive slider drags from settings.
  void setThresholds({required double warningMeters, required double dangerMeters}) {
    assert(dangerMeters < warningMeters);
    _warning = warningMeters;
    _danger = dangerMeters;
  }

  /// Feed a new depth reading and return the resulting level.
  AlertLevel update(double depthMeters) {
    final next = _compute(depthMeters);
    if (next != _level) {
      _level = next;
      onTransition?.call(next);
    }
    return _level;
  }

  /// Stateless classification — no hysteresis. Use for static colour
  /// mapping (e.g. plotting historical samples on the map).
  static AlertLevel classify({
    required double depthMeters,
    required double warningMeters,
    required double dangerMeters,
  }) {
    if (depthMeters <= dangerMeters) return AlertLevel.danger;
    if (depthMeters <= warningMeters) return AlertLevel.warning;
    return AlertLevel.safe;
  }

  AlertLevel _compute(double d) {
    switch (_level) {
      case AlertLevel.safe:
        return classify(
          depthMeters: d,
          warningMeters: _warning,
          dangerMeters: _danger,
        );
      case AlertLevel.warning:
        if (d <= _danger) return AlertLevel.danger;
        if (d > _warning + hysteresisMeters) return AlertLevel.safe;
        return AlertLevel.warning;
      case AlertLevel.danger:
        if (d > _danger + hysteresisMeters) {
          if (d > _warning + hysteresisMeters) return AlertLevel.safe;
          return AlertLevel.warning;
        }
        return AlertLevel.danger;
    }
  }
}
