import 'package:drift/drift.dart';
import 'common_columns.dart';

@DataClassName('AttachmentData')
class Attachments extends Table with TableColumnsAudit {
  // entityType: 'fuel', 'service', 'expense'
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get filePath => text()(); // App-private relative path
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
}
