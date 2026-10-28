import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

final activeVehiclesStreamProvider = StreamProvider<List<VehicleData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.vehicles)
        ..where((tbl) => tbl.deletedAt.isNull() & tbl.isArchived.equals(false))
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
      .watch();
});

final currentVehicleProvider = Provider<VehicleData?>((ref) {
  final vehiclesAsync = ref.watch(activeVehiclesStreamProvider);
  final selectedId = ref.watch(settingsProvider).selectedVehicleId;

  return vehiclesAsync.when(
    data: (vehicles) {
      if (vehicles.isEmpty) return null;
      if (selectedId != null) {
        final found = vehicles.where((v) => v.id == selectedId);
        if (found.isNotEmpty) return found.first;
      }
      return vehicles.first;
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});
