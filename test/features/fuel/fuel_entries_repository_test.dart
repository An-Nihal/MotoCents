import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/features/fuel/data/fuel_entries_repository.dart';

void main() {
  late AppDatabase db;
  late FuelEntriesRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = FuelEntriesRepository(db);

    // Create a vehicle first
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'v1',
            name: 'Honda Civic',
            vehicleType: 'car',
            fuelType: 'octane',
            plateNumber: 'DHAKA GA-55-6677',
            initialOdometer: const Value(10000.0),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('FuelEntriesRepository - Save, Autocomplete, Soft Delete', () async {
    final now = DateTime.now();

    // 1. Save entry
    await repo.saveEntry(
      FuelEntriesCompanion.insert(
        id: 'fe1',
        vehicleId: 'v1',
        entryDateTime: now,
        odometer: 10450.0,
        quantity: 30.0,
        pricePerUnit: 130.0,
        totalCost: 3900.0,
        fuelType: 'octane',
        stationName: const Value('Meghna Petroleum, Airport'),
        isFullTank: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // 2. Query entries stream
    final entries = await repo.watchFuelEntriesForVehicle('v1').first;
    expect(entries.length, 1);
    expect(entries.first.odometer, 10450.0);
    expect(entries.first.totalCost, 3900.0);

    // 3. Station names autocomplete
    final stations = await repo.getStationNames('v1');
    expect(stations.contains('Meghna Petroleum, Airport'), true);

    // 4. Latest entry
    final latest = await repo.getLatestEntryForVehicle('v1');
    expect(latest?.id, 'fe1');

    // 5. Soft delete
    await repo.softDelete('fe1');
    final afterDelete = await repo.watchFuelEntriesForVehicle('v1').first;
    expect(afterDelete.isEmpty, true);

    // 6. Restore
    await repo.restore('fe1');
    final afterRestore = await repo.watchFuelEntriesForVehicle('v1').first;
    expect(afterRestore.length, 1);

    // 7. getEntriesForVehicle returns list sorted ascending
    await repo.saveEntry(
      FuelEntriesCompanion.insert(
        id: 'fe2',
        vehicleId: 'v1',
        entryDateTime: now.add(const Duration(days: 5)),
        odometer: 10800.0,
        quantity: 25.0,
        pricePerUnit: 130.0,
        totalCost: 3250.0,
        fuelType: 'octane',
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await repo.saveEntry(
      FuelEntriesCompanion.insert(
        id: 'fe3',
        vehicleId: 'v1',
        entryDateTime: now.add(const Duration(days: 10)),
        odometer: 11200.0,
        quantity: 28.0,
        pricePerUnit: 130.0,
        totalCost: 3640.0,
        fuelType: 'octane',
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    final allEntries = await repo.getEntriesForVehicle('v1');
    expect(allEntries.length, 3);
    expect(allEntries[0].id, 'fe1');
    expect(allEntries[1].id, 'fe2');
    expect(allEntries[2].id, 'fe3');

    // Middle entry fe2 has previous entry fe1 and next entry fe3
    final idx = allEntries.indexWhere((e) => e.id == 'fe2');
    expect(allEntries[idx - 1].odometer, 10450.0);
    expect(allEntries[idx + 1].odometer, 11200.0);
  });
}
