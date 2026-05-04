// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navDepth => 'Profondeur';

  @override
  String get navMap => 'Carte';

  @override
  String get navSettings => 'Réglages';

  @override
  String get mapTitle => 'Carte';

  @override
  String get mapRecenterTooltip => 'Centrer sur moi';

  @override
  String get depthLabel => 'PROFONDEUR';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get thresholdWarning => 'Seuil avertissement';

  @override
  String get thresholdDanger => 'Seuil danger';

  @override
  String get sourceSectionTitle => 'Source de profondeur';

  @override
  String get sourceModeSim => 'Sim';

  @override
  String get sourceModeBt => 'Bluetooth';

  @override
  String get sourceModeWifi => 'WiFi';

  @override
  String get sourceModeReplay => 'Rejouer';

  @override
  String get replayPanelTitle => 'Rejouer une session enregistrée';

  @override
  String get replayPanelSubtitle =>
      'Lit les profondeurs et positions enregistrées des dernières 24 h, à leur cadence d\'origine. Utile pour rejouer une sortie sans matériel.';

  @override
  String get replayLoopLabel => 'Lecture en boucle';

  @override
  String get replayNoDataYet =>
      'Aucune session récente à rejouer. Utilise un autre mode pour enregistrer une sortie d\'abord.';

  @override
  String replaySamplesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échantillons enregistrés disponibles',
      one: '1 échantillon enregistré disponible',
    );
    return '$_temp0';
  }

  @override
  String get simulationPanelTitle => 'Mode simulation';

  @override
  String get simulationPanelSubtitle =>
      'Émet des profondeurs fictives selon un scénario.';

  @override
  String get scenarioLabel => 'Scénario :';

  @override
  String get scenarioApproach => 'Approche progressive';

  @override
  String get scenarioSuddenDanger => 'Danger soudain';

  @override
  String get scenarioUnstable => 'Lecture instable';

  @override
  String get scenarioManual => 'Manuel';

  @override
  String get bluetoothPanelTitle => 'Sondeur Bluetooth';

  @override
  String get noDeviceSelected => 'Aucun appareil sélectionné';

  @override
  String get chooseDevice => 'Choisir';

  @override
  String get forgetDevice => 'Oublier l\'appareil';

  @override
  String get wifiPanelTitle => 'Sondeur WiFi (NMEA UDP)';

  @override
  String get wifiPanelSubtitle =>
      'Connectez votre téléphone au WiFi du sondeur (Deeper, Lowrance, passerelle marine…) puis activez l\'envoi NMEA 0183 sur UDP dans son application.';

  @override
  String get wifiPortLabel => 'Port UDP :';

  @override
  String wifiPortDefaultHint(int port) {
    return '(défaut : $port)';
  }

  @override
  String get unitLabel => 'Unité';

  @override
  String get unitMeters => 'Mètres';

  @override
  String get unitFeet => 'Pieds';

  @override
  String get pickerTitle => 'Choisir un sondeur';

  @override
  String pickerError(String error) {
    return 'Impossible de lister les appareils Bluetooth.\n$error';
  }

  @override
  String get pickerEmpty =>
      'Aucun appareil appairé.\nAppairez d\'abord le sondeur depuis les réglages Bluetooth de votre téléphone.';

  @override
  String get noName => '(sans nom)';

  @override
  String get cancel => 'Annuler';

  @override
  String connStatusDisconnected(String transport) {
    return '$transport : déconnecté';
  }

  @override
  String connStatusConnecting(String transport) {
    return '$transport : connexion…';
  }

  @override
  String connStatusConnected(String transport) {
    return '$transport : connecté';
  }

  @override
  String connStatusError(String transport) {
    return '$transport : erreur';
  }
}
