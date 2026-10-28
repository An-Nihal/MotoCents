import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class ServiceEntryWithItems {
  final ServiceEntryData entry;
  final List<ServiceItemData> items;
  final List<ServiceTypeData> itemTypes;

  const ServiceEntryWithItems({
    required this.entry,
    required this.items,
    required this.itemTypes,
  });
}

class ServicesRepository {
  final AppDatabase _db;

  ServicesRepository(this._db);

  // 1. Service Types
  Stream<List<ServiceTypeData>> watchServiceTypes() {
    return (_db.select(_db.serviceTypes)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<void> createServiceType(ServiceTypesCompanion companion) async {
    await _db.into(_db.serviceTypes).insert(companion);
  }

  Future<void> softDeleteServiceType(String id) async {
    await (_db.update(_db.serviceTypes)..where((tbl) => tbl.id.equals(id))).write(
      ServiceTypesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 2. Service Entries & Items
  Stream<List<ServiceEntryWithItems>> watchServiceEntriesForVehicle(String vehicleId) {
    final entriesQuery = _db.select(_db.serviceEntries)
      ..where((tbl) => tbl.vehicleId.equals(vehicleId) & tbl.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.serviceDate, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.odometer, mode: OrderingMode.desc),
      ]);

    return entriesQuery.watch().asyncMap((entries) async {
      final List<ServiceEntryWithItems> results = [];
      for (final entry in entries) {
        final items = await (_db.select(_db.serviceItems)
              ..where((t) => t.serviceEntryId.equals(entry.id) & t.deletedAt.isNull()))
            .get();

        final typeIds = items.map((i) => i.serviceTypeId).toList();
        final types = await (_db.select(_db.serviceTypes)
              ..where((t) => t.id.isIn(typeIds)))
            .get();

        results.add(ServiceEntryWithItems(
          entry: entry,
          items: items,
          itemTypes: types,
        ));
      }
      return results;
    });
  }

  Future<void> saveServiceEntry({
    required ServiceEntriesCompanion entry,
    required List<ServiceItemsCompanion> items,
  }) async {
    await _db.transaction(() async {
      // 1. Insert or update the service entry
      final existing = await (_db.select(_db.serviceEntries)
            ..where((t) => t.id.equals(entry.id.value)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.serviceEntries).insert(entry);
      } else {
        await (_db.update(_db.serviceEntries)..where((t) => t.id.equals(entry.id.value)))
            .write(entry.copyWith(updatedAt: Value(DateTime.now())));
        // Delete previous items on update
        await (_db.delete(_db.serviceItems)
              ..where((t) => t.serviceEntryId.equals(entry.id.value)))
            .go();
      }

      // 2. Insert items
      for (final item in items) {
        await _db.into(_db.serviceItems).insert(item);
      }

      // 3. Auto-update active reminders for the vehicle matching these service types
      final odo = entry.odometer.value;
      final date = entry.serviceDate.value;
      final vehicleId = entry.vehicleId.value;

      for (final item in items) {
        final typeId = item.serviceTypeId.value;
        final matchingReminders = await (_db.select(_db.serviceReminders)
              ..where((t) =>
                  t.vehicleId.equals(vehicleId) &
                  t.serviceTypeId.equals(typeId) &
                  t.deletedAt.isNull()))
            .get();

        for (final reminder in matchingReminders) {
          double? nextDueOdo;
          DateTime? nextDueDate;

          if (reminder.intervalDistance != null && reminder.intervalDistance! > 0) {
            nextDueOdo = odo + reminder.intervalDistance!;
          }
          if (reminder.intervalMonths != null && reminder.intervalMonths! > 0) {
            nextDueDate = DateTime(
              date.year,
              date.month + reminder.intervalMonths!,
              date.day,
            );
          }

          await (_db.update(_db.serviceReminders)
                ..where((t) => t.id.equals(reminder.id)))
              .write(
            ServiceRemindersCompanion(
              lastServiceOdometer: Value(odo),
              lastServiceDate: Value(date),
              dueOdometer: Value(nextDueOdo),
              dueDate: Value(nextDueDate),
              isDismissed: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    });
  }

  Future<void> softDeleteServiceEntry(String id) async {
    await (_db.update(_db.serviceEntries)..where((t) => t.id.equals(id))).write(
      ServiceEntriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreServiceEntry(String id) async {
    await (_db.update(_db.serviceEntries)..where((t) => t.id.equals(id))).write(
      ServiceEntriesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // 3. Service Reminders
  Stream<List<ServiceReminderData>> watchRemindersForVehicle(String vehicleId) {
    return (_db.select(_db.serviceReminders)
          ..where((tbl) => tbl.vehicleId.equals(vehicleId) & tbl.deletedAt.isNull()))
        .watch();
  }

  Future<void> saveReminder(ServiceRemindersCompanion reminder) async {
    final existing = await (_db.select(_db.serviceReminders)
          ..where((t) => t.id.equals(reminder.id.value)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.serviceReminders).insert(reminder);
    } else {
      await (_db.update(_db.serviceReminders)
            ..where((t) => t.id.equals(reminder.id.value)))
          .write(reminder.copyWith(updatedAt: Value(DateTime.now())));
    }
  }

  Future<void> deleteReminder(String id) async {
    await (_db.update(_db.serviceReminders)..where((t) => t.id.equals(id))).write(
      ServiceRemindersCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ServicesRepository(db);
});
