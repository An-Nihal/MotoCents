import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

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
    Locale('bn'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Fuel & Service Log'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get navFuel;

  /// No description provided for @navService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get navService;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @addFuel.
  ///
  /// In en, this message translates to:
  /// **'Add Fuel'**
  String get addFuel;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// No description provided for @allVehicles.
  ///
  /// In en, this message translates to:
  /// **'All Vehicles'**
  String get allVehicles;

  /// No description provided for @noVehiclesTitle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle added yet'**
  String get noVehiclesTitle;

  /// No description provided for @noVehiclesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle to start tracking fuel, mileage, services, and documents.'**
  String get noVehiclesDescription;

  /// No description provided for @addFirstVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addFirstVehicle;

  /// No description provided for @currentOdometer.
  ///
  /// In en, this message translates to:
  /// **'Current Odometer'**
  String get currentOdometer;

  /// No description provided for @lastMileage.
  ///
  /// In en, this message translates to:
  /// **'Last Mileage'**
  String get lastMileage;

  /// No description provided for @avgMileage.
  ///
  /// In en, this message translates to:
  /// **'Average Mileage'**
  String get avgMileage;

  /// No description provided for @spendThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spend This Month'**
  String get spendThisMonth;

  /// No description provided for @nextServiceDue.
  ///
  /// In en, this message translates to:
  /// **'Next Service Due'**
  String get nextServiceDue;

  /// No description provided for @documentsExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Documents Expiring Soon'**
  String get documentsExpiringSoon;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More Features'**
  String get moreTitle;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Other Expenses'**
  String get expenses;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @milesUnit.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get milesUnit;

  /// No description provided for @litresUnit.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get litresUnit;

  /// No description provided for @gallonsUnit.
  ///
  /// In en, this message translates to:
  /// **'gal'**
  String get gallonsUnit;

  /// No description provided for @kmPerLitre.
  ///
  /// In en, this message translates to:
  /// **'km/L'**
  String get kmPerLitre;

  /// No description provided for @litresPer100km.
  ///
  /// In en, this message translates to:
  /// **'L/100km'**
  String get litresPer100km;

  /// No description provided for @milesPerGallon.
  ///
  /// In en, this message translates to:
  /// **'MPG'**
  String get milesPerGallon;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @stationInsights.
  ///
  /// In en, this message translates to:
  /// **'Station Insights'**
  String get stationInsights;

  /// No description provided for @stationInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze fuel prices, efficiency, and quality across stations'**
  String get stationInsightsSubtitle;

  /// No description provided for @tripCalculator.
  ///
  /// In en, this message translates to:
  /// **'Trip Cost Calculator'**
  String get tripCalculator;

  /// No description provided for @tripCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate fuel volume and total budget for your trips'**
  String get tripCalculatorSubtitle;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt / Odometer'**
  String get scanReceipt;

  /// No description provided for @scanReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extract fuel volume, price, total, and odometer using OCR'**
  String get scanReceiptSubtitle;

  /// No description provided for @mileageDropAlert.
  ///
  /// In en, this message translates to:
  /// **'Mileage Drop Alert'**
  String get mileageDropAlert;

  /// No description provided for @mileageDropAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Mileage dropped by more than 15% compared to your vehicle\'s average.'**
  String get mileageDropAlertDesc;

  /// No description provided for @checkTyrePressure.
  ///
  /// In en, this message translates to:
  /// **'Check tyre pressure, air filter, or fuel quality'**
  String get checkTyrePressure;

  /// No description provided for @bestEfficiencyStation.
  ///
  /// In en, this message translates to:
  /// **'Best Fuel Efficiency'**
  String get bestEfficiencyStation;

  /// No description provided for @lowestPriceStation.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price Station'**
  String get lowestPriceStation;

  /// No description provided for @roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round Trip'**
  String get roundTrip;

  /// No description provided for @estimatedFuel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Fuel'**
  String get estimatedFuel;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// No description provided for @costPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Cost Per Person'**
  String get costPerPerson;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Data'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle history PDF, CSV/Excel export, data import'**
  String get reportsSubtitle;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup file (.fslbackup), cloud share, restore'**
  String get backupSubtitle;

  /// No description provided for @vehicleHistoryReport.
  ///
  /// In en, this message translates to:
  /// **'Vehicle History Report'**
  String get vehicleHistoryReport;

  /// No description provided for @vehicleHistoryReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive service & fuel log summary suitable for car buyers'**
  String get vehicleHistoryReportDesc;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly & Annual Summary'**
  String get monthlyReport;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @importFuelCsv.
  ///
  /// In en, this message translates to:
  /// **'Import Fuel Logs from CSV'**
  String get importFuelCsv;

  /// No description provided for @columnMapping.
  ///
  /// In en, this message translates to:
  /// **'Column Mapping'**
  String get columnMapping;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Encrypted Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreBackup;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup Password'**
  String get backupPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Backup'**
  String get lastBackup;

  /// No description provided for @backupReminder.
  ///
  /// In en, this message translates to:
  /// **'Backup Reminder (Every 30 Days)'**
  String get backupReminder;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Fuel & Mileage Tracking'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast fill-up entry in under 10 seconds. Precise full-to-full mileage calculation, partial fill support, and station price insights.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Alerts & Document Vault'**
  String get onboardingMaintenanceTitle;

  /// No description provided for @onboardingMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Never miss an oil change or token renewal. Keep driving licenses, fitness certificates, and smart cards secure offline.'**
  String get onboardingMaintenanceDesc;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Offline & Private'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your documents and vehicle records never leave your device. All sensitive files are encrypted with AES-256-GCM.'**
  String get onboardingPrivacyDesc;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units & Measurement'**
  String get units;

  /// No description provided for @distanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnit;

  /// No description provided for @volumeUnit.
  ///
  /// In en, this message translates to:
  /// **'Volume Unit'**
  String get volumeUnit;

  /// No description provided for @economyUnit.
  ///
  /// In en, this message translates to:
  /// **'Fuel Economy Unit'**
  String get economyUnit;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alerts'**
  String get notifications;

  /// No description provided for @serviceReminders.
  ///
  /// In en, this message translates to:
  /// **'Service Reminders'**
  String get serviceReminders;

  /// No description provided for @documentReminders.
  ///
  /// In en, this message translates to:
  /// **'Document Expiry Alerts'**
  String get documentReminders;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder Time'**
  String get reminderTime;

  /// No description provided for @vaultSecurity.
  ///
  /// In en, this message translates to:
  /// **'Vault Security'**
  String get vaultSecurity;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometrics;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change Master PIN'**
  String get changePin;

  /// No description provided for @autoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get autoLockTimeout;

  /// No description provided for @manageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Manage Custom Categories'**
  String get manageMetadata;

  /// No description provided for @manageServiceTypes.
  ///
  /// In en, this message translates to:
  /// **'Service Types'**
  String get manageServiceTypes;

  /// No description provided for @manageExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get manageExpenseCategories;

  /// No description provided for @manageDocumentTypes.
  ///
  /// In en, this message translates to:
  /// **'Document Types'**
  String get manageDocumentTypes;

  /// No description provided for @addCustomType.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Type'**
  String get addCustomType;

  /// No description provided for @customTypeName.
  ///
  /// In en, this message translates to:
  /// **'Type Name'**
  String get customTypeName;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data Guarantee'**
  String get privacyPolicy;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Fuel & Service Log'**
  String get aboutApp;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
