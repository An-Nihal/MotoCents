import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/core/localization/generated/app_localizations.dart';
import 'package:fuel_and_service_log/core/providers/database_provider.dart';
import 'package:fuel_and_service_log/core/providers/vehicles_provider.dart';
import 'package:fuel_and_service_log/features/fuel/data/fuel_entries_repository.dart';
import 'package:fuel_and_service_log/features/smart/presentation/trip_cost_calculator_screen.dart';

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
            id: 'veh-trip-1',
            name: 'Honda Vezel',
            vehicleType: 'car',
            plateNumber: 'DHK-5544',
            fuelType: 'hybrid',
            initialOdometer: const drift.Value(15000.0),
            tankCapacity: const drift.Value(40.0),
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
        home: TripCostCalculatorScreen(),
      ),
    );
  }

  group('Trip Cost Calculator Screen Widget Tests', () {
    testWidgets('Renders calculator cards, distance inputs, and results', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ESTIMATED TRIP COST'), findsOneWidget);
      expect(find.text('Trip Distance'), findsOneWidget);
      expect(find.text('+50 km'), findsOneWidget);
      expect(find.text('+100 km'), findsOneWidget);
      expect(find.text('Round Trip (2x distance)'), findsOneWidget);

      // Tap +50 km preset chip
      final chip50 = find.text('+50 km');
      await tester.tap(chip50);
      await tester.pump();

      // Tap Round Trip switch
      final roundTripSwitch = find.byType(Switch);
      expect(roundTripSwitch, findsOneWidget);
      await tester.tap(roundTripSwitch);
      await tester.pump();

      // Increment passenger count
      final addPassengerBtn = find.byIcon(Icons.add_circle_outline);
      expect(addPassengerBtn, findsOneWidget);
      await tester.tap(addPassengerBtn);
      await tester.pump();

      expect(find.text('2 people'), findsOneWidget);
      expect(find.textContaining('per person'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
