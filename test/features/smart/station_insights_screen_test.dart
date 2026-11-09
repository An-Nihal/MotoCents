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
import 'package:motocents/features/fuel/data/fuel_entries_repository.dart';
import 'package:motocents/features/smart/presentation/station_insights_screen.dart';

void main() {
  late AppDatabase testDb;
  late FuelEntriesRepository fuelRepo;
  late VehicleData testVehicle;

  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDb = AppDatabase(NativeDatabase.memory());
    fuelRepo = FuelEntriesRepository(testDb);

    testVehicle = await testDb.into(testDb.vehicles).insertReturning(
          VehiclesCompanion.insert(
            id: 'veh-ins-1',
            name: 'Toyota Corolla',
            vehicleType: 'car',
            plateNumber: 'DHK-7788',
            fuelType: 'octane',
            initialOdometer: const drift.Value(10000.0),
            distanceUnit: const drift.Value('km'),
            volumeUnit: const drift.Value('L'),
            economyUnit: const drift.Value('km/L'),
          ),
        );
  });

  tearDown(() async {
    await testDb.close();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        fuelEntriesRepositoryProvider.overrideWithValue(fuelRepo),
        currentVehicleProvider.overrideWith((ref) => testVehicle),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('bn')],
        home: StationInsightsScreen(),
      ),
    );
  }

  group('Station Insights Screen Widget Tests', () {
    testWidgets('Renders empty state when no station entries exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Station Insights Yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Renders Hero cards, station analytics cards, and benchmark bar with data',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();

      // Seed entries
      await testDb.into(testDb.fuelEntries).insert(
            FuelEntriesCompanion.insert(
              id: 'fe-1',
              vehicleId: testVehicle.id,
              entryDateTime: now.subtract(const Duration(days: 15)),
              odometer: 10100.0,
              quantity: 20.0,
              pricePerUnit: 130.0,
              totalCost: 2600.0,
              fuelType: 'octane',
              stationName: const drift.Value('Padma Oil'),
              isFullTank: const drift.Value(true),
              isMissedPrevious: const drift.Value(false),
            ),
          );

      await testDb.into(testDb.fuelEntries).insert(
            FuelEntriesCompanion.insert(
              id: 'fe-2',
              vehicleId: testVehicle.id,
              entryDateTime: now.subtract(const Duration(days: 10)),
              odometer: 10380.0, // 280 km on 20L = 14 km/L on Padma fuel
              quantity: 25.0,
              pricePerUnit: 125.0, // Cheaper price at Meghna
              totalCost: 3125.0,
              fuelType: 'octane',
              stationName: const drift.Value('Meghna Oil'),
              isFullTank: const drift.Value(true),
              isMissedPrevious: const drift.Value(false),
            ),
          );

      await testDb.into(testDb.fuelEntries).insert(
            FuelEntriesCompanion.insert(
              id: 'fe-3',
              vehicleId: testVehicle.id,
              entryDateTime: now.subtract(const Duration(days: 5)),
              odometer: 10650.0, // 270 km on 25L = 10.8 km/L on Meghna fuel
              quantity: 20.0,
              pricePerUnit: 132.0,
              totalCost: 2640.0,
              fuelType: 'octane',
              stationName: const drift.Value('Padma Oil'),
              isFullTank: const drift.Value(true),
              isMissedPrevious: const drift.Value(false),
            ),
          );

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Hero Highlights
      expect(find.text('Best Mileage'), findsOneWidget);
      expect(find.text('Lowest Price'), findsOneWidget);

      // Verify Station Titles
      expect(find.text('Padma Oil'), findsWidgets);
      expect(find.text('Meghna Oil'), findsWidgets);

      // Verify Benchmarks
      expect(find.text('Vehicle Baseline Average:'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
