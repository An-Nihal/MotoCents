import 'package:drift/drift.dart';
import 'common_columns.dart';

@DataClassName('VehicleData')
class Vehicles extends Table with TableColumnsAudit {
  TextColumn get name => text()();
  // Types: car, motorcycle, cng, microbus, truck, other
  TextColumn get vehicleType => text()();
  TextColumn get make => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  // Fuel types: petrol, octane, diesel, cng, lpg, electric, hybrid
  TextColumn get fuelType => text()();
  TextColumn get plateNumber => text()();
  RealColumn get tankCapacity => real().nullable()();
  RealColumn get initialOdometer => real().withDefault(const Constant(0.0))();
  TextColumn get photoPath => text().nullable()();

  // Units
  TextColumn get distanceUnit => text().withDefault(const Constant('km'))(); // km, mi
  TextColumn get volumeUnit => text().withDefault(const Constant('L'))(); // L, gal
  TextColumn get economyUnit => text().withDefault(const Constant('km/L'))(); // km/L, L/100km, MPG

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
