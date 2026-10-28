import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../fuel/data/fuel_entries_repository.dart';
import '../../data/csv_import_service.dart';
import '../../data/data_export_service.dart';
import '../../data/pdf_report_service.dart';

final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService();
});

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  final fuelRepo = ref.watch(fuelEntriesRepositoryProvider);
  return CsvImportService(fuelRepo: fuelRepo);
});
