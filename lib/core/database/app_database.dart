import 'package:drift/drift.dart';
import 'connection/native.dart' as conn;
import 'seed/default_seeds.dart';
import 'tables/attachment_tables.dart';
import 'tables/document_tables.dart';
import 'tables/expense_tables.dart';
import 'tables/fuel_entries_table.dart';
import 'tables/service_tables.dart';
import 'tables/settings_table.dart';
import 'tables/vehicles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Vehicles,
  FuelEntries,
  ServiceTypes,
  ServiceEntries,
  ServiceItems,
  ServiceReminders,
  ExpenseCategories,
  Expenses,
  DocumentTypes,
  Documents,
  DocumentFiles,
  Attachments,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? conn.openConnection());

  factory AppDatabase.defaults() => AppDatabase();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await DefaultSeeds.seedDatabase(this);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Schema migrations for subsequent versions
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
