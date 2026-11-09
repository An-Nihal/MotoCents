import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/core/localization/generated/app_localizations.dart';
import 'package:motocents/core/providers/database_provider.dart';
import 'package:motocents/features/fuel/presentation/fuel_entry_form_screen.dart';

void main() {
  testWidgets('FuelEntryFormScreen - Live 2-of-3 auto calculation and save',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    final vehicle = VehicleData(
      id: 'v1',
      name: 'Yamaha MT-15',
      vehicleType: 'motorcycle',
      fuelType: 'octane',
      plateNumber: 'DHAKA HA-99-8877',
      initialOdometer: 5000.0,
      distanceUnit: 'km',
      volumeUnit: 'L',
      economyUnit: 'km/L',
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Insert into database to satisfy foreign key constraint
    await testDb.into(testDb.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicle.id,
            name: vehicle.name,
            vehicleType: vehicle.vehicleType,
            fuelType: vehicle.fuelType,
            plateNumber: vehicle.plateNumber,
            initialOdometer: drift.Value(vehicle.initialOdometer),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FuelEntryFormScreen(vehicle: vehicle),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify fields exist
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Log Fill-Up'), findsOneWidget);
    expect(find.text('Tank Fill State'), findsOneWidget);

    // Enter Odometer reading
    final odoField = find.widgetWithText(TextFormField, 'Total Odometer Reading (km) *');
    expect(odoField, findsOneWidget);
    await tester.enterText(odoField, '5450');
    await tester.pump();

    // Enter Quantity (10 L)
    final qtyField = find.widgetWithText(TextFormField, 'Quantity (L) *');
    expect(qtyField, findsOneWidget);
    await tester.enterText(qtyField, '10');
    await tester.pump();

    // Enter Price per unit (130)
    final priceField = find.widgetWithText(TextFormField, 'Price / L *');
    expect(priceField, findsOneWidget);
    await tester.enterText(priceField, '130');
    await tester.pump();

    // Check that Total Cost is auto-calculated as 1300.00
    final totalField = find.widgetWithText(TextFormField, 'Total Cost *');
    expect(totalField, findsOneWidget);
    final totalWidget = tester.widget<TextFormField>(totalField);
    expect(totalWidget.controller?.text, '1300.00');

    // Tap Save button in AppBar
    final saveButton = find.widgetWithText(TextButton, 'Save');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify entry was saved in the database
    final entries = await testDb.select(testDb.fuelEntries).get();
    expect(entries.length, 1);
    expect(entries.first.odometer, 5450.0);
    expect(entries.first.quantity, 10.0);
    expect(entries.first.pricePerUnit, 130.0);
    expect(entries.first.totalCost, 1300.0);
    expect(entries.first.isFullTank, true);

    // Unmount and close DB cleanly
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await testDb.close();
  });
}
