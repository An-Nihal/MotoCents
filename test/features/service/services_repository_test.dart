import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/features/service/data/services_repository.dart';

void main() {
  late AppDatabase db;
  late ServicesRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ServicesRepository(db);

    // Insert test vehicle
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'v1',
            name: 'Toyota Noah',
            vehicleType: 'microbus',
            fuelType: 'octane',
            plateNumber: 'DHAKA CHA-12-3456',
            initialOdometer: const Value(50000.0),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('ServicesRepository - Transactional multi-item entry and reminder auto-update', () async {
    final now = DateTime.now();

    // 1. Get an existing seeded service type (e.g. engine_oil)
    final types = await db.select(db.serviceTypes).get();
    final oilType = types.firstWhere((t) => t.code == 'engine_oil');

    // 2. Create an active reminder for engine oil
    await repo.saveReminder(
      ServiceRemindersCompanion.insert(
        id: 'rem_oil',
        vehicleId: 'v1',
        serviceTypeId: oilType.id,
        reminderType: const Value('both'),
        intervalDistance: const Value(3000.0),
        intervalMonths: const Value(3),
        lastServiceOdometer: const Value(50000.0),
        lastServiceDate: Value(now),
        dueOdometer: const Value(53000.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // 3. Log a maintenance service at 53200 km containing the engine oil change item
    final serviceDate = now.add(const Duration(days: 60));
    await repo.saveServiceEntry(
      entry: ServiceEntriesCompanion.insert(
        id: 'serv_1',
        vehicleId: 'v1',
        serviceDate: serviceDate,
        odometer: 53200.0,
        laborCost: const Value(500.0),
        totalCost: 3500.0,
        garageName: const Value('Uttara Motors Workshop'),
        createdAt: Value(serviceDate),
        updatedAt: Value(serviceDate),
      ),
      items: [
        ServiceItemsCompanion.insert(
          id: 'item_1',
          serviceEntryId: 'serv_1',
          serviceTypeId: oilType.id,
          cost: const Value(3000.0),
          partsUsed: const Value('Total Quartz 9000 5W-30'),
          createdAt: Value(serviceDate),
          updatedAt: Value(serviceDate),
        ),
      ],
    );

    // 4. Verify entry & items retrieved
    final entries = await repo.watchServiceEntriesForVehicle('v1').first;
    expect(entries.length, 1);
    expect(entries.first.entry.odometer, 53200.0);
    expect(entries.first.entry.totalCost, 3500.0);
    expect(entries.first.items.length, 1);
    expect(entries.first.items.first.partsUsed, 'Total Quartz 9000 5W-30');
    expect(entries.first.itemTypes.first.name, oilType.name);

    // 5. Verify reminder was automatically rolled forward!
    final reminders = await repo.watchRemindersForVehicle('v1').first;
    expect(reminders.length, 1);
    final updatedReminder = reminders.first;
    expect(updatedReminder.lastServiceOdometer, 53200.0);
    // New due odometer = 53200 + 3000 = 56200
    expect(updatedReminder.dueOdometer, 56200.0);

    // 6. Test soft delete and restore
    await repo.softDeleteServiceEntry('serv_1');
    final afterDelete = await repo.watchServiceEntriesForVehicle('v1').first;
    expect(afterDelete.isEmpty, true);

    await repo.restoreServiceEntry('serv_1');
    final afterRestore = await repo.watchServiceEntriesForVehicle('v1').first;
    expect(afterRestore.length, 1);
  });
}
