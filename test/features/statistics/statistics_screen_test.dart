import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/core/providers/vehicles_provider.dart';
import 'package:motocents/features/documents/domain/vault_crypto_service.dart';
import 'package:motocents/features/expenses/data/expenses_repository.dart';
import 'package:motocents/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:motocents/features/fuel/data/fuel_entries_repository.dart';
import 'package:motocents/features/service/data/services_repository.dart';
import 'package:motocents/features/statistics/presentation/statistics_screen.dart';
import '../documents/documents_repository_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late MockSecureStorage mockStorage;
  late VaultCryptoService cryptoService;
  late ExpensesRepository expensesRepo;
  late FuelEntriesRepository fuelRepo;
  late ServicesRepository serviceRepo;
  late VehicleData testVehicle;

  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('stats_widget_test_');
    testDb = AppDatabase(NativeDatabase.memory());

    mockStorage = MockSecureStorage();
    cryptoService = VaultCryptoService(
      secureStorage: mockStorage,
      getBaseDirectory: () async => tempDir,
    );

    expensesRepo = ExpensesRepository(
      testDb,
      cryptoService: cryptoService,
    );
    fuelRepo = FuelEntriesRepository(testDb);
    serviceRepo = ServicesRepository(testDb);

    // Seed vehicle
    testVehicle = await testDb.into(testDb.vehicles).insertReturning(
          VehiclesCompanion.insert(
            id: 'veh-stat-1',
            name: 'Honda Civic',
            vehicleType: 'car',
            plateNumber: 'CTG-9988',
            fuelType: 'octane',
            initialOdometer: const drift.Value(20000.0),
            distanceUnit: const drift.Value('km'),
            volumeUnit: const drift.Value('L'),
            economyUnit: const drift.Value('km/L'),
          ),
        );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestApp({
    VehicleData? currentVehicle,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        expensesRepositoryProvider.overrideWithValue(expensesRepo),
        fuelEntriesRepositoryProvider.overrideWithValue(fuelRepo),
        servicesRepositoryProvider.overrideWithValue(serviceRepo),
        currentVehicleProvider.overrideWith((ref) => currentVehicle ?? testVehicle),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('bn')],
        home: StatisticsScreen(),
      ),
    );
  }

  group('Statistics Screen Widget Tests', () {
    testWidgets('Renders empty state when vehicle has no entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Honda Civic'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('1 Year'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      expect(find.text('No Statistics Yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });

    testWidgets('Renders KPI metrics, Donut chart, and category breakdown with data',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();

      // Seed 2 fuel entries (for mileage calculation)
      await testDb.into(testDb.fuelEntries).insert(
            FuelEntriesCompanion.insert(
              id: 'fuel-1',
              vehicleId: testVehicle.id,
              entryDateTime: now.subtract(const Duration(days: 10)),
              odometer: 20100.0,
              quantity: 25.0,
              pricePerUnit: 130.0,
              totalCost: 3250.0,
              fuelType: 'octane',
              isFullTank: const drift.Value(true),
              isMissedPrevious: const drift.Value(false),
            ),
          );
      await testDb.into(testDb.fuelEntries).insert(
            FuelEntriesCompanion.insert(
              id: 'fuel-2',
              vehicleId: testVehicle.id,
              entryDateTime: now.subtract(const Duration(days: 2)),
              odometer: 20450.0,
              quantity: 30.0,
              pricePerUnit: 130.0,
              totalCost: 3900.0,
              fuelType: 'octane',
              isFullTank: const drift.Value(true),
              isMissedPrevious: const drift.Value(false),
            ),
          );

      // Seed 1 expense
      final washCat = (await testDb.select(testDb.expenseCategories).get())
          .firstWhere((c) => c.code == 'wash');
      await testDb.into(testDb.expenses).insert(
            ExpensesCompanion.insert(
              id: 'exp-wash-1',
              vehicleId: testVehicle.id,
              categoryId: washCat.id,
              amount: 500.0,
              date: now.subtract(const Duration(days: 5)),
              odometer: const drift.Value(20300.0),
              notes: const drift.Value('Full interior detailing'),
            ),
          );

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify KPI Metric Tiles
      expect(find.text('Total Spend (TCO)'), findsOneWidget);
      expect(find.text('Cost per km'), findsOneWidget);
      expect(find.text('Cost per Day'), findsOneWidget);
      expect(find.text('Average Economy'), findsOneWidget);

      // Verify Chart Cards titles
      expect(find.text('Cost Breakdown (TCO)'), findsOneWidget);
      expect(find.text('Monthly Running Cost'), findsOneWidget);
      expect(find.text('Fuel Efficiency Trend'), findsOneWidget);
      expect(find.text('Other Expenses by Category'), findsOneWidget);
      expect(find.text('Wash'), findsOneWidget);

      // Switch period to "All Time"
      final allTimeChip = find.text('All Time');
      expect(allTimeChip, findsOneWidget);
      await tester.tap(allTimeChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should still display metrics cleanly
      expect(find.text('Total Spend (TCO)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await testDb.close();
    });
  });
}
