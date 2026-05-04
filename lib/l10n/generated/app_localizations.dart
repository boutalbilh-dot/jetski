import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// Bottom-nav label for the depth screen
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get navDepth;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @mapRecenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Center on me'**
  String get mapRecenterTooltip;

  /// No description provided for @depthLabel.
  ///
  /// In en, this message translates to:
  /// **'DEPTH'**
  String get depthLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @thresholdWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning threshold'**
  String get thresholdWarning;

  /// No description provided for @thresholdDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger threshold'**
  String get thresholdDanger;

  /// No description provided for @sourceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Depth source'**
  String get sourceSectionTitle;

  /// No description provided for @sourceModeSim.
  ///
  /// In en, this message translates to:
  /// **'Sim'**
  String get sourceModeSim;

  /// No description provided for @sourceModeBt.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get sourceModeBt;

  /// No description provided for @sourceModeWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get sourceModeWifi;

  /// No description provided for @sourceModeReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get sourceModeReplay;

  /// No description provided for @replayPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay a recorded session'**
  String get replayPanelTitle;

  /// No description provided for @replayPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replays the depths and positions recorded in the last 24 h, at their original cadence. Useful for testing the pipeline without hardware.'**
  String get replayPanelSubtitle;

  /// No description provided for @replayLoopLabel.
  ///
  /// In en, this message translates to:
  /// **'Loop playback'**
  String get replayLoopLabel;

  /// No description provided for @replayNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No recent session to replay yet. Use another mode to record a trip first.'**
  String get replayNoDataYet;

  /// No description provided for @replaySamplesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recorded sample available} other{{count} recorded samples available}}'**
  String replaySamplesAvailable(int count);

  /// No description provided for @simulationPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulation mode'**
  String get simulationPanelTitle;

  /// No description provided for @simulationPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emits fake depths following a chosen scenario.'**
  String get simulationPanelSubtitle;

  /// No description provided for @scenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'Scenario:'**
  String get scenarioLabel;

  /// No description provided for @scenarioApproach.
  ///
  /// In en, this message translates to:
  /// **'Gradual approach'**
  String get scenarioApproach;

  /// No description provided for @scenarioSuddenDanger.
  ///
  /// In en, this message translates to:
  /// **'Sudden danger'**
  String get scenarioSuddenDanger;

  /// No description provided for @scenarioUnstable.
  ///
  /// In en, this message translates to:
  /// **'Unstable reading'**
  String get scenarioUnstable;

  /// No description provided for @scenarioManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get scenarioManual;

  /// No description provided for @bluetoothPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth sounder'**
  String get bluetoothPanelTitle;

  /// No description provided for @noDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'No device selected'**
  String get noDeviceSelected;

  /// No description provided for @chooseDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseDevice;

  /// No description provided for @forgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forget device'**
  String get forgetDevice;

  /// No description provided for @wifiPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'WiFi sounder (NMEA UDP)'**
  String get wifiPanelTitle;

  /// No description provided for @wifiPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone to the sounder\'s WiFi (Deeper, Lowrance, marine gateway…) then enable NMEA 0183 over UDP in its app.'**
  String get wifiPanelSubtitle;

  /// No description provided for @wifiPortLabel.
  ///
  /// In en, this message translates to:
  /// **'UDP port:'**
  String get wifiPortLabel;

  /// No description provided for @wifiPortDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'(default: {port})'**
  String wifiPortDefaultHint(int port);

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get unitMeters;

  /// No description provided for @unitFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get unitFeet;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a sounder'**
  String get pickerTitle;

  /// No description provided for @pickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not list Bluetooth devices.\n{error}'**
  String pickerError(String error);

  /// No description provided for @pickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No paired devices.\nFirst pair the sounder from your phone\'s Bluetooth settings.'**
  String get pickerEmpty;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get noName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @connStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{transport}: disconnected'**
  String connStatusDisconnected(String transport);

  /// No description provided for @connStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'{transport}: connecting…'**
  String connStatusConnecting(String transport);

  /// No description provided for @connStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'{transport}: connected'**
  String connStatusConnected(String transport);

  /// No description provided for @connStatusError.
  ///
  /// In en, this message translates to:
  /// **'{transport}: error'**
  String connStatusError(String transport);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
