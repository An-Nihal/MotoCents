import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class FuelEntriesRepository {
  final AppDatabase _db;

  FuelEntriesRepository(this._db);

  Stream<List<FuelEntryData>> watchFuelEntriesForVehicle(String vehicleId) {
    return (_db.select(_db.fuelEntries)
          ..where((tbl) => tbl.vehicleId.equals(vehicleId) & tbl.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.entryDateTime, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.odometer, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<FuelEntryData?> getLatestEntryForVehicle(String vehicleId) {
    return (_db.select(_db.fuelEntries)
          ..where((tbl) => tbl.vehicleId.equals(vehicleId) & tbl.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.entryDateTime, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.odometer, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<String>> getStationNames(String vehicleId) async {
    final entries = await (_db.selectOnly(_db.fuelEntries, distinct: true)
          ..addColumns([_db.fuelEntries.stationName])
          ..where(
            _db.fuelEntries.vehicleId.equals(vehicleId) &
                _db.fuelEntries.stationName.isNotNull() &
                _db.fuelEntries.deletedAt.isNull(),
          ))
        .get();

    return entries
        .map((r) => r.read(_db.fuelEntries.stationName))
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  Future<void> saveEntry(FuelEntriesCompanion companion) async {
    final existing = await (_db.select(_db.fuelEntries)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.fuelEntries).insert(companion);
    } else {
      await (_db.update(_db.fuelEntries)..where((t) => t.id.equals(companion.id.value)))
          .write(companion.copyWith(updatedAt: Value(DateTime.now())));
    }
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.fuelEntries)..where((t) => t.id.equals(id))).write(
      FuelEntriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.fuelEntries)..where((t) => t.id.equals(id))).write(
      FuelEntriesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final fuelEntriesRepositoryProvider = Provider<FuelEntriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FuelEntriesRepository(db);
});

final fuelEntriesForCurrentVehicleProvider =
    StreamProvider.autoDispose<List<FuelEntryData>>((ref) {
  final repo = ref.watch(fuelEntriesRepositoryProvider);
  final db = ref.watch(databaseProvider);
  // Watch active vehicles to know selected vehicle
  final activeVehicles =
      (db.select(db.vehicles)..where((tbl) => tbl.deletedAt.isNull())).watch();

  // Return stream based on currently selected vehicle
  return activeVehicles.asyncExpand((vehicles) {
    if (vehicles.isEmpty) return Stream.value([]);
    // Find selected or first
    final vehicleId = vehicles.first.id;
    return repo.watchFuelEntriesForVehicle(vehicleId);
  });
});
