import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class VehiclesRepository {
  final AppDatabase _db;

  VehiclesRepository(this._db);

  Stream<List<VehicleData>> watchAllVehicles({bool includeArchived = false}) {
    final query = _db.select(_db.vehicles)..where((tbl) => tbl.deletedAt.isNull());
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    return query.watch();
  }

  Future<VehicleData?> getVehicleById(String id) {
    return (_db.select(_db.vehicles)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> createVehicle(VehiclesCompanion companion) async {
    await _db.into(_db.vehicles).insert(companion);
  }

  Future<void> updateVehicle(VehiclesCompanion companion) async {
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(companion.id.value))).write(
      companion.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> setArchived(String id, bool isArchived) async {
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(id))).write(
      VehiclesCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(id))).write(
      VehiclesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(id))).write(
      VehiclesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VehiclesRepository(db);
});
