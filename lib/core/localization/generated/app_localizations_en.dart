// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fuel & Service Log';

  @override
  String get navHome => 'Home';

  @override
  String get navFuel => 'Fuel';

  @override
  String get navService => 'Service';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navMore => 'More';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get addFuel => 'Add Fuel';

  @override
  String get addService => 'Add Service';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get selectVehicle => 'Select Vehicle';

  @override
  String get allVehicles => 'All Vehicles';

  @override
  String get noVehiclesTitle => 'No vehicle added yet';

  @override
  String get noVehiclesDescription =>
      'Add your first vehicle to start tracking fuel, mileage, services, and documents.';

  @override
  String get addFirstVehicle => 'Add Vehicle';

  @override
  String get currentOdometer => 'Current Odometer';

  @override
  String get lastMileage => 'Last Mileage';

  @override
  String get avgMileage => 'Average Mileage';

  @override
  String get spendThisMonth => 'Spend This Month';

  @override
  String get nextServiceDue => 'Next Service Due';

  @override
  String get documentsExpiringSoon => 'Documents Expiring Soon';

  @override
  String get moreTitle => 'More Features';

  @override
  String get expenses => 'Other Expenses';

  @override
  String get statistics => 'Statistics';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System Default';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get kmUnit => 'km';

  @override
  String get milesUnit => 'mi';

  @override
  String get litresUnit => 'L';

  @override
  String get gallonsUnit => 'gal';

  @override
  String get kmPerLitre => 'km/L';

  @override
  String get litresPer100km => 'L/100km';

  @override
  String get milesPerGallon => 'MPG';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get undo => 'Undo';

  @override
  String get stationInsights => 'Station Insights';

  @override
  String get stationInsightsSubtitle =>
      'Analyze fuel prices, efficiency, and quality across stations';

  @override
  String get tripCalculator => 'Trip Cost Calculator';

  @override
  String get tripCalculatorSubtitle =>
      'Estimate fuel volume and total budget for your trips';

  @override
  String get scanReceipt => 'Scan Receipt / Odometer';

  @override
  String get scanReceiptSubtitle =>
      'Extract fuel volume, price, total, and odometer using OCR';

  @override
  String get mileageDropAlert => 'Mileage Drop Alert';

  @override
  String get mileageDropAlertDesc =>
      'Mileage dropped by more than 15% compared to your vehicle\'s average.';

  @override
  String get checkTyrePressure =>
      'Check tyre pressure, air filter, or fuel quality';

  @override
  String get bestEfficiencyStation => 'Best Fuel Efficiency';

  @override
  String get lowestPriceStation => 'Lowest Price Station';

  @override
  String get roundTrip => 'Round Trip';

  @override
  String get estimatedFuel => 'Estimated Fuel';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get costPerPerson => 'Cost Per Person';

  @override
  String get passengers => 'Passengers';

  @override
  String get reportsTitle => 'Reports & Data';

  @override
  String get reportsSubtitle =>
      'Vehicle history PDF, CSV/Excel export, data import';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupSubtitle =>
      'Encrypted backup file (.fslbackup), cloud share, restore';

  @override
  String get vehicleHistoryReport => 'Vehicle History Report';

  @override
  String get vehicleHistoryReportDesc =>
      'Comprehensive service & fuel log summary suitable for car buyers';

  @override
  String get monthlyReport => 'Monthly & Annual Summary';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get importData => 'Import Data';

  @override
  String get importFuelCsv => 'Import Fuel Logs from CSV';

  @override
  String get columnMapping => 'Column Mapping';

  @override
  String get createBackup => 'Create Encrypted Backup';

  @override
  String get restoreBackup => 'Restore from Backup';

  @override
  String get backupPassword => 'Backup Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get lastBackup => 'Last Backup';

  @override
  String get backupReminder => 'Backup Reminder (Every 30 Days)';

  @override
  String get onboardingWelcomeTitle => 'Smart Fuel & Mileage Tracking';

  @override
  String get onboardingWelcomeDesc =>
      'Fast fill-up entry in under 10 seconds. Precise full-to-full mileage calculation, partial fill support, and station price insights.';

  @override
  String get onboardingMaintenanceTitle => 'Service Alerts & Document Vault';

  @override
  String get onboardingMaintenanceDesc =>
      'Never miss an oil change or token renewal. Keep driving licenses, fitness certificates, and smart cards secure offline.';

  @override
  String get onboardingPrivacyTitle => '100% Offline & Private';

  @override
  String get onboardingPrivacyDesc =>
      'Your documents and vehicle records never leave your device. All sensitive files are encrypted with AES-256-GCM.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get units => 'Units & Measurement';

  @override
  String get distanceUnit => 'Distance Unit';

  @override
  String get volumeUnit => 'Volume Unit';

  @override
  String get economyUnit => 'Fuel Economy Unit';

  @override
  String get notifications => 'Notifications & Alerts';

  @override
  String get serviceReminders => 'Service Reminders';

  @override
  String get documentReminders => 'Document Expiry Alerts';

  @override
  String get reminderTime => 'Daily Reminder Time';

  @override
  String get vaultSecurity => 'Vault Security';

  @override
  String get biometrics => 'Biometric Unlock';

  @override
  String get changePin => 'Change Master PIN';

  @override
  String get autoLockTimeout => 'Auto-Lock Timeout';

  @override
  String get manageMetadata => 'Manage Custom Categories';

  @override
  String get manageServiceTypes => 'Service Types';

  @override
  String get manageExpenseCategories => 'Expense Categories';

  @override
  String get manageDocumentTypes => 'Document Types';

  @override
  String get addCustomType => 'Add Custom Type';

  @override
  String get customTypeName => 'Type Name';

  @override
  String get privacyPolicy => 'Privacy & Data Guarantee';

  @override
  String get aboutApp => 'About Fuel & Service Log';
}
