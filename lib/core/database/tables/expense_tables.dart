import 'package:drift/drift.dart';
import 'common_columns.dart';
import 'vehicles_table.dart';

@DataClassName('ExpenseCategoryData')
class ExpenseCategories extends Table with TableColumnsAudit {
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

@DataClassName('ExpenseData')
class Expenses extends Table with TableColumnsAudit {
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get odometer => real().nullable()();
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
}
