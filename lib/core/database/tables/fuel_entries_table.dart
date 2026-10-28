import 'package:drift/drift.dart';
import 'common_columns.dart';
import 'vehicles_table.dart';

@DataClassName('FuelEntryData')
class FuelEntries extends Table with TableColumnsAudit {
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  DateTimeColumn get entryDateTime => dateTime()();
  RealColumn get odometer => real()();
  RealColumn get tripDistance => real().nullable()();
  RealColumn get quantity => real()();
  RealColumn get pricePerUnit => real()();
  RealColumn get totalCost => real()();
  TextColumn get fuelType => text()();
  TextColumn get stationName => text().nullable()();
  BoolColumn get isFullTank => boolean().withDefault(const Constant(true))();
  BoolColumn get isMissedPrevious => boolean().withDefault(const Constant(false))();
  RealColumn get calculatedMileage => real().nullable()();
  RealColumn get distanceSinceLast => real().nullable()();
  RealColumn get costPerKm => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
}
