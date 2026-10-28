import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    // Open in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Database initializes with default seeds', () async {
    // Verify default service types seeded
    final serviceTypes = await db.select(db.serviceTypes).get();
    expect(serviceTypes.isNotEmpty, true);
    expect(
      serviceTypes.any((st) => st.code == 'engine_oil'),
      true,
      reason: 'Engine oil service type should be seeded',
    );

    // Verify default expense categories seeded
    final expenseCategories = await db.select(db.expenseCategories).get();
    expect(expenseCategories.isNotEmpty, true);
    expect(
      expenseCategories.any((ec) => ec.code == 'parking'),
      true,
      reason: 'Parking expense category should be seeded',
    );

    // Verify default document types seeded
    final docTypes = await db.select(db.documentTypes).get();
    expect(docTypes.isNotEmpty, true);
    expect(
      docTypes.any((dt) => dt.code == 'driving_license'),
      true,
      reason: 'Driving license document type should be seeded',
    );

    // Verify default settings seeded
    final settings = await db.select(db.settings).get();
    expect(settings.isNotEmpty, true);
    expect(settings.any((s) => s.id == 'currency' && s.value == 'BDT'), true);
    expect(settings.any((s) => s.id == 'language' && s.value == 'en'), true);
  });

  test('Can insert and retrieve a vehicle with UUID and audit fields', () async {
    final vehicleId = uuid.v4();
    final now = DateTime.now();

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            name: 'Yamaha FZ-S',
            vehicleType: 'motorcycle',
            fuelType: 'octane',
            plateNumber: 'DHAKA METRO HA-12-3456',
            initialOdometer: const Value(1500.0),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final vehicles = await db.select(db.vehicles).get();
    expect(vehicles.length, 1);
    expect(vehicles.first.id, vehicleId);
    expect(vehicles.first.name, 'Yamaha FZ-S');
    expect(vehicles.first.plateNumber, 'DHAKA METRO HA-12-3456');
    expect(vehicles.first.distanceUnit, 'km');
    expect(vehicles.first.volumeUnit, 'L');
    expect(vehicles.first.economyUnit, 'km/L');
  });

  test('Can record fuel fill-ups linked to vehicle', () async {
    final vehicleId = uuid.v4();
    final fillUpId = uuid.v4();
    final now = DateTime.now();

    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: vehicleId,
            name: 'Toyota Corolla',
            vehicleType: 'car',
            fuelType: 'octane',
            plateNumber: 'DHAKA GA-22-3344',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await db.into(db.fuelEntries).insert(
          FuelEntriesCompanion.insert(
            id: fillUpId,
            vehicleId: vehicleId,
            entryDateTime: now,
            odometer: 15450.0,
            quantity: 35.5,
            pricePerUnit: 130.0,
            totalCost: 4615.0,
            fuelType: 'octane',
            stationName: const Value('Padma Oil, Tejgaon'),
            isFullTank: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final entries = await db.select(db.fuelEntries).get();
    expect(entries.length, 1);
    expect(entries.first.totalCost, 4615.0);
    expect(entries.first.isFullTank, true);
    expect(entries.first.vehicleId, vehicleId);
  });
}
