import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/features/garage/data/vehicles_repository.dart';

void main() {
  late AppDatabase db;
  late VehiclesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = VehiclesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('VehiclesRepository - CRUD, archive, and soft delete', () async {
    final now = DateTime.now();

    // 1. Create Vehicle
    await repo.createVehicle(
      VehiclesCompanion.insert(
        id: 'v1',
        name: 'Toyota Allion',
        vehicleType: 'car',
        fuelType: 'octane',
        plateNumber: 'DHAKA GA-11-2233',
        initialOdometer: const Value(25000.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    var vehicle = await repo.getVehicleById('v1');
    expect(vehicle, isNotNull);
    expect(vehicle!.name, 'Toyota Allion');
    expect(vehicle.isArchived, false);
    expect(vehicle.deletedAt, isNull);

    // 2. Update Vehicle
    await repo.updateVehicle(
      const VehiclesCompanion(
        id: Value('v1'),
        name: Value('Toyota Allion A15'),
      ),
    );
    vehicle = await repo.getVehicleById('v1');
    expect(vehicle!.name, 'Toyota Allion A15');

    // 3. Archive Vehicle
    await repo.setArchived('v1', true);
    vehicle = await repo.getVehicleById('v1');
    expect(vehicle!.isArchived, true);

    // Watch active vehicles should exclude archived
    var activeList = await repo.watchAllVehicles(includeArchived: false).first;
    expect(activeList.isEmpty, true);

    var allList = await repo.watchAllVehicles(includeArchived: true).first;
    expect(allList.length, 1);

    // 4. Soft Delete Vehicle
    await repo.softDelete('v1');
    allList = await repo.watchAllVehicles(includeArchived: true).first;
    expect(allList.isEmpty, true);

    // 5. Restore Vehicle
    await repo.restore('v1');
    allList = await repo.watchAllVehicles(includeArchived: true).first;
    expect(allList.length, 1);
  });
}
