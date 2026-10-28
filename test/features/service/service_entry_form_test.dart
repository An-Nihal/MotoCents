import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/core/localization/generated/app_localizations.dart';
import 'package:fuel_and_service_log/core/providers/database_provider.dart';
import 'package:fuel_and_service_log/features/service/presentation/service_entry_form_screen.dart';

void main() {
  testWidgets('ServiceEntryFormScreen - Multi-item and labor auto-sum',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    final vehicle = VehicleData(
      id: 'v_service',
      name: 'Hyundai Tucson',
      vehicleType: 'car',
      fuelType: 'petrol',
      plateNumber: 'DHAKA GA-77-8899',
      initialOdometer: 20000.0,
      distanceUnit: 'km',
      volumeUnit: 'L',
      economyUnit: 'km/L',
      isArchived: false,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

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
          home: ServiceEntryFormScreen(vehicle: vehicle),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Log Maintenance'), findsOneWidget);

    // Enter Odometer
    final odoField =
        find.widgetWithText(TextFormField, 'Odometer Reading (km) *');
    expect(odoField, findsOneWidget);
    await tester.enterText(odoField, '25000');
    await tester.pump();

    // Enter Garage Name
    final garageField = find.widgetWithText(TextFormField, 'Garage / Workshop');
    expect(garageField, findsOneWidget);
    await tester.enterText(garageField, 'Navana Toyota Service Center');
    await tester.pump();

    // Enter Labor Cost
    final laborField = find.widgetWithText(TextFormField, 'Labour Cost');
    expect(laborField, findsOneWidget);
    await tester.enterText(laborField, '800');
    await tester.pump();

    // Tap "Add Item" button
    final addItemBtn = find.widgetWithText(TextButton, 'Add Item');
    expect(addItemBtn, findsOneWidget);
    await tester.tap(addItemBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // BottomSheet should open with 'Add Service Item'
    expect(find.text('Add Service Item'), findsOneWidget);

    // Enter item cost in bottom sheet
    final itemCostField = find.widgetWithText(TextFormField, 'Item Cost');
    expect(itemCostField, findsOneWidget);
    await tester.enterText(itemCostField, '3200');
    await tester.pump();

    // Tap 'Save Item' in bottom sheet
    final saveItemBtn = find.widgetWithText(FilledButton, 'Save Item');
    expect(saveItemBtn, findsOneWidget);
    await tester.tap(saveItemBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Check that Total Cost is auto-calculated: 3200 + 800 = 4000.00
    final totalField = find.widgetWithText(TextFormField, 'Total Cost *');
    expect(totalField, findsOneWidget);
    final totalWidget = tester.widget<TextFormField>(totalField);
    expect(totalWidget.controller?.text, '4000.00');

    // Tap Save in AppBar
    final saveEntryBtn = find.widgetWithText(TextButton, 'Save');
    expect(saveEntryBtn, findsOneWidget);
    await tester.tap(saveEntryBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify database record was created
    final entries = await testDb.select(testDb.serviceEntries).get();
    expect(entries.length, 1);
    expect(entries.first.odometer, 25000.0);
    expect(entries.first.laborCost, 800.0);
    expect(entries.first.totalCost, 4000.0);
    expect(entries.first.garageName, 'Navana Toyota Service Center');

    final items = await testDb.select(testDb.serviceItems).get();
    expect(items.length, 1);
    expect(items.first.cost, 3200.0);

    // Unmount and clean up
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await testDb.close();
  });
}
