import 'package:drift/drift.dart';
import 'common_columns.dart';
import 'vehicles_table.dart';

@DataClassName('DocumentTypeData')
class DocumentTypes extends Table with TableColumnsAudit {
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  BoolColumn get isVehicleSpecific => boolean().withDefault(const Constant(true))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

@DataClassName('DocumentData')
class Documents extends Table with TableColumnsAudit {
  // Nullable if linked to user/driver (e.g. driving license, NID)
  TextColumn get vehicleId => text().nullable().references(Vehicles, #id)();
  TextColumn get documentTypeId => text().references(DocumentTypes, #id)();
  TextColumn get title => text()();
  TextColumn get documentNumber => text().nullable()();
  DateTimeColumn get issueDate => dateTime().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get issuingAuthority => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isQuickShow => boolean().withDefault(const Constant(false))();
  // Comma-separated days before expiry e.g. "30,15,7,1"
  TextColumn get reminderDaysBefore => text().withDefault(const Constant('30,15,7,1'))();
}

@DataClassName('DocumentFileData')
class DocumentFiles extends Table with TableColumnsAudit {
  TextColumn get documentId => text().references(Documents, #id)();
  TextColumn get filePath => text()(); // App-private relative path (encrypted)
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get pageNumber => integer().withDefault(const Constant(1))();
  IntColumn get fileSizeBytes => integer().nullable()();
}
