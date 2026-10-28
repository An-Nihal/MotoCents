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

  @override
  String get garageAndVehicles => 'Garage & Vehicles';

  @override
  String get myGarage => 'My Garage';

  @override
  String get myGarageSubtitle => 'Add, edit, and manage all your vehicles';

  @override
  String get expensesSubtitle => 'Parking, tolls, fines, and other costs';

  @override
  String get statisticsSubtitle =>
      'Mileage trends, cost breakdown, spend charts';

  @override
  String get features => 'Features';

  @override
  String get settingsSubtitle =>
      'Units, reminders, vault security, custom types';

  @override
  String get aboutAndPrivacy => 'About & Privacy';

  @override
  String get localOnlyAndPrivate => 'Local-Only & Private';

  @override
  String get localOnlyAndPrivateDesc => 'Your data never leaves your device.';

  @override
  String get version => 'Version';

  @override
  String get versionSubtitle => '1.0.0 (Build 1) • Offline First';

  @override
  String get logService => 'Log Service';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get viewVault => 'View Vault';

  @override
  String get viewStatisticsCostAnalysis => 'View Statistics & Cost Analysis';

  @override
  String get statisticsCostAnalysisSubtitle =>
      'TCO breakdown, fuel economy, and spending trends';

  @override
  String get noActiveReminders =>
      'No active reminders. Tap \"Set Reminder\" to get notified.';

  @override
  String get noExpiringDocuments =>
      'No expiring documents in the next 30 days.';

  @override
  String get logFillUp => 'Log Fill-Up';

  @override
  String get stations => 'Stations';

  @override
  String get tripCalc => 'Trip Calc';

  @override
  String get bestMileage => 'Best Mileage';

  @override
  String get worstMileage => 'Worst Mileage';

  @override
  String get totalFuel => 'Total Fuel';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get avgPrice => 'Avg. Price';

  @override
  String get deleteEntryTitle => 'Delete Entry?';

  @override
  String get deleteFuelEntryConfirm =>
      'Are you sure you want to remove this fuel entry?';

  @override
  String get fuelFillUp => 'Fuel Fill-Up';

  @override
  String get partialFill => 'Partial Fill';

  @override
  String get missedFillUp => 'Missed Fill-Up';

  @override
  String get fillUpsCount => 'fill-ups';

  @override
  String get noFuelEntriesYet => 'No fuel entries yet';

  @override
  String get tapToLogFuel => 'Tap + to log your first fill-up';

  @override
  String get filterAll => 'All';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allTime => 'All Time';

  @override
  String get allTimeSpend => 'All-Time Spend';

  @override
  String get totalLogs => 'Total Logs';

  @override
  String get filterByCategory => 'Filter by Category (All)';

  @override
  String get allCategories => 'All Categories';

  @override
  String get noExpensesLogged => 'No Expenses Logged';

  @override
  String get noMatchingExpenses => 'No Matching Expenses';

  @override
  String get expensesEmptyDesc =>
      'Track other costs like Parking, Tolls, Wash, Traffic Fines, Insurance, and Accessories.';

  @override
  String get expensesFilterEmptyDesc =>
      'Try selecting a different time filter or category above.';

  @override
  String get deleteExpenseTitle => 'Delete Expense?';

  @override
  String get deleteExpenseConfirm =>
      'Are you sure you want to delete this expense record?';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get statisticsAndCharts => 'Statistics & Charts';

  @override
  String get period3Months => '3 Months';

  @override
  String get period6Months => '6 Months';

  @override
  String get period1Year => '1 Year';

  @override
  String get totalSpendTco => 'Total Spend (TCO)';

  @override
  String get costPer => 'Cost per';

  @override
  String get costPerDay => 'Cost per Day';

  @override
  String get averageEconomy => 'Average Economy';

  @override
  String get costBreakdownTitle => 'Cost Breakdown (TCO)';

  @override
  String get costBreakdownSubtitle =>
      'Distribution across Fuel, Service, and Other Expenses';

  @override
  String get monthlyRunningCost => 'Monthly Running Cost';

  @override
  String get monthlyRunningCostSubtitle =>
      'Total spending trend per calendar month';

  @override
  String get monthlySpendingTrend => 'Monthly Spending Trend';

  @override
  String get monthlySpendingTrendSubtitle =>
      'Combined breakdown of monthly maintenance, fuel & expenses';

  @override
  String get fuelEfficiencyTrend => 'Fuel Efficiency Trend';

  @override
  String get fuelEfficiencyTrendSubtitle =>
      'Full-to-full calculated economy across fill-ups';

  @override
  String get fuelEconomyTrend => 'Fuel Economy Trend';

  @override
  String get fuelEconomyTrendSubtitle =>
      'Historical mileage performance across fill-ups';

  @override
  String get expensesByCategory => 'Other Expenses by Category';

  @override
  String get expensesByCategorySubtitle =>
      'Breakdown of parking, tolls, wash, fines, etc.';

  @override
  String get noStatisticsAvailable => 'No Statistics Yet';

  @override
  String get noStatisticsDesc =>
      'Add fuel fill-ups or service records to view analytics.';
}
