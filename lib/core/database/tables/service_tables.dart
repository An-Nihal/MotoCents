import 'package:drift/drift.dart';
import 'common_columns.dart';
import 'vehicles_table.dart';

@DataClassName('ServiceTypeData')
class ServiceTypes extends Table with TableColumnsAudit {
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  RealColumn get defaultDistanceInterval => real().nullable()();
  IntColumn get defaultMonthInterval => integer().nullable()();
}

@DataClassName('ServiceEntryData')
class ServiceEntries extends Table with TableColumnsAudit {
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  DateTimeColumn get serviceDate => dateTime()();
  RealColumn get odometer => real()();
  RealColumn get laborCost => real().withDefault(const Constant(0.0))();
  RealColumn get totalCost => real()();
  TextColumn get garageName => text().nullable()();
  TextColumn get mechanicName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
}

@DataClassName('ServiceItemData')
class ServiceItems extends Table with TableColumnsAudit {
  TextColumn get serviceEntryId => text().references(ServiceEntries, #id)();
  TextColumn get serviceTypeId => text().references(ServiceTypes, #id)();
  TextColumn get customTypeName => text().nullable()();
  RealColumn get cost => real().withDefault(const Constant(0.0))();
  TextColumn get partsUsed => text().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('ServiceReminderData')
class ServiceReminders extends Table with TableColumnsAudit {
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get serviceTypeId => text().references(ServiceTypes, #id)();
  // reminderType: 'distance', 'time', 'both'
  TextColumn get reminderType => text().withDefault(const Constant('both'))();
  RealColumn get intervalDistance => real().nullable()();
  IntColumn get intervalMonths => integer().nullable()();
  RealColumn get lastServiceOdometer => real().nullable()();
  DateTimeColumn get lastServiceDate => dateTime().nullable()();
  RealColumn get dueOdometer => real().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isDismissed => boolean().withDefault(const Constant(false))();
  IntColumn get notificationId => integer().nullable()();
}
