// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navDepth => 'Depth';

  @override
  String get navMap => 'Map';

  @override
  String get navSettings => 'Settings';

  @override
  String get mapTitle => 'Map';

  @override
  String get depthLabel => 'DEPTH';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get thresholdWarning => 'Warning threshold';

  @override
  String get thresholdDanger => 'Danger threshold';

  @override
  String get sourceSectionTitle => 'Depth source';

  @override
  String get sourceModeSim => 'Sim';

  @override
  String get sourceModeBt => 'Bluetooth';

  @override
  String get sourceModeWifi => 'WiFi';

  @override
  String get sourceModeReplay => 'Replay';

  @override
  String get replayPanelTitle => 'Replay a recorded session';

  @override
  String get replayPanelSubtitle =>
      'Replays the depths and positions recorded in the last 24 h, at their original cadence. Useful for testing the pipeline without hardware.';

  @override
  String get replayLoopLabel => 'Loop playback';

  @override
  String get replayNoDataYet =>
      'No recent session to replay yet. Use another mode to record a trip first.';

  @override
  String replaySamplesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorded samples available',
      one: '1 recorded sample available',
    );
    return '$_temp0';
  }

  @override
  String get simulationPanelTitle => 'Simulation mode';

  @override
  String get simulationPanelSubtitle =>
      'Emits fake depths following a chosen scenario.';

  @override
  String get scenarioLabel => 'Scenario:';

  @override
  String get scenarioApproach => 'Gradual approach';

  @override
  String get scenarioSuddenDanger => 'Sudden danger';

  @override
  String get scenarioUnstable => 'Unstable reading';

  @override
  String get scenarioManual => 'Manual';

  @override
  String get bluetoothPanelTitle => 'Bluetooth sounder';

  @override
  String get noDeviceSelected => 'No device selected';

  @override
  String get chooseDevice => 'Choose';

  @override
  String get forgetDevice => 'Forget device';

  @override
  String get wifiPanelTitle => 'WiFi sounder (NMEA UDP)';

  @override
  String get wifiPanelSubtitle =>
      'Connect your phone to the sounder\'s WiFi (Deeper, Lowrance, marine gateway…) then enable NMEA 0183 over UDP in its app.';

  @override
  String get wifiPortLabel => 'UDP port:';

  @override
  String wifiPortDefaultHint(int port) {
    return '(default: $port)';
  }

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitMeters => 'Meters';

  @override
  String get unitFeet => 'Feet';

  @override
  String get pickerTitle => 'Choose a sounder';

  @override
  String pickerError(String error) {
    return 'Could not list Bluetooth devices.\n$error';
  }

  @override
  String get pickerEmpty =>
      'No paired devices.\nFirst pair the sounder from your phone\'s Bluetooth settings.';

  @override
  String get noName => '(no name)';

  @override
  String get cancel => 'Cancel';

  @override
  String connStatusDisconnected(String transport) {
    return '$transport: disconnected';
  }

  @override
  String connStatusConnecting(String transport) {
    return '$transport: connecting…';
  }

  @override
  String connStatusConnected(String transport) {
    return '$transport: connected';
  }

  @override
  String connStatusError(String transport) {
    return '$transport: error';
  }
}
