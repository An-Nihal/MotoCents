import 'package:drift/drift.dart';

@DataClassName('SettingData')
class Settings extends Table {
  TextColumn get id => text()(); // setting key (e.g., 'currency', 'language', 'theme_mode')
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
