import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../fuel/data/fuel_entries_repository.dart';

class CsvColumnMapping {
  int dateIndex;
  int odometerIndex;
  int quantityIndex;
  int priceIndex;
  int totalCostIndex;
  int? stationIndex;
  int? notesIndex;

  CsvColumnMapping({
    this.dateIndex = -1,
    this.odometerIndex = -1,
    this.quantityIndex = -1,
    this.priceIndex = -1,
    this.totalCostIndex = -1,
    this.stationIndex,
    this.notesIndex,
  });

  bool get isValid =>
      dateIndex >= 0 &&
      odometerIndex >= 0 &&
      (quantityIndex >= 0 || totalCostIndex >= 0);
}

class CsvImportPreview {
  final List<String> headers;
  final CsvColumnMapping detectedMapping;
  final List<List<dynamic>> sampleRows;
  final int totalDataRowCount;

  const CsvImportPreview({
    required this.headers,
    required this.detectedMapping,
    required this.sampleRows,
    required this.totalDataRowCount,
  });
}

class CsvImportResult {
  final int successCount;
  final int skippedCount;
  final List<String> errors;

  const CsvImportResult({
    required this.successCount,
    required this.skippedCount,
    this.errors = const [],
  });
}

class CsvImportService {
  final FuelEntriesRepository fuelRepo;
  final _uuid = const Uuid();

  CsvImportService({required this.fuelRepo});

  /// Analyzes CSV content, extracts header columns, guesses column mapping, and returns preview rows.
  CsvImportPreview parseCsvPreview(String csvContent) {
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(eol: '\n').convert(
      normalized,
      shouldParseNumbers: true,
    );

    if (rows.isEmpty) {
      return CsvImportPreview(
        headers: [],
        detectedMapping: CsvColumnMapping(),
        sampleRows: [],
        totalDataRowCount: 0,
      );
    }

    final headers = rows.first.map((c) => c.toString().trim()).toList();
    final mapping = CsvColumnMapping();

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();

      if (mapping.dateIndex == -1 && (h.contains('date') || h.contains('time') || h.contains('তারিখ'))) {
        mapping.dateIndex = i;
      } else if (mapping.odometerIndex == -1 &&
          (h.contains('odo') || h.contains('km') || h.contains('reading') || h.contains('মিটার'))) {
        mapping.odometerIndex = i;
      } else if (mapping.quantityIndex == -1 &&
          (h.contains('qty') || h.contains('quantity') || h.contains('litr') || h.contains('volume') || h.contains('পরিমাণ'))) {
        mapping.quantityIndex = i;
      } else if (mapping.priceIndex == -1 &&
          (h.contains('rate') || h.contains('price') || h.contains('দর'))) {
        mapping.priceIndex = i;
      } else if (mapping.totalCostIndex == -1 &&
          (h.contains('total') || h.contains('amount') || h.contains('cost') || h.contains('টাকা') || h.contains('মোট'))) {
        mapping.totalCostIndex = i;
      } else if (mapping.stationIndex == null &&
          (h.contains('station') || h.contains('pump') || h.contains('পাম্প'))) {
        mapping.stationIndex = i;
      } else if (mapping.notesIndex == null &&
          (h.contains('note') || h.contains('remark') || h.contains('মন্তব্য'))) {
        mapping.notesIndex = i;
      }
    }

    final dataRows = rows.skip(1).toList();
    final sampleRows = dataRows.take(3).toList();

    return CsvImportPreview(
      headers: headers,
      detectedMapping: mapping,
      sampleRows: sampleRows,
      totalDataRowCount: dataRows.length,
    );
  }

  /// Imports rows into database using the provided column mapping.
  Future<CsvImportResult> importFuelEntries({
    required String csvContent,
    required String vehicleId,
    required String defaultFuelType,
    required CsvColumnMapping mapping,
  }) async {
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(eol: '\n').convert(
      normalized,
      shouldParseNumbers: true,
    );

    if (rows.length < 2) {
      return const CsvImportResult(successCount: 0, skippedCount: 0);
    }

    int successCount = 0;
    int skippedCount = 0;
    final List<String> errors = [];
    final now = DateTime.now();

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || row.every((c) => c == null || c.toString().trim().isEmpty)) {
        continue;
      }

      try {
        // Parse date
        final dateVal = row[mapping.dateIndex];
        final entryDate = DateTime.tryParse(dateVal.toString().trim()) ?? now;

        // Parse odometer
        final odoVal = row[mapping.odometerIndex];
        final odometer = double.tryParse(odoVal.toString().trim()) ?? 0.0;
        if (odometer <= 0) {
          skippedCount++;
          errors.add('Row $r: invalid odometer ($odoVal)');
          continue;
        }

        // Parse quantity, price, total
        double quantity = 0.0;
        if (mapping.quantityIndex >= 0 && mapping.quantityIndex < row.length) {
          quantity = double.tryParse(row[mapping.quantityIndex].toString().trim()) ?? 0.0;
        }

        double price = 0.0;
        if (mapping.priceIndex >= 0 && mapping.priceIndex < row.length) {
          price = double.tryParse(row[mapping.priceIndex].toString().trim()) ?? 0.0;
        }

        double total = 0.0;
        if (mapping.totalCostIndex >= 0 && mapping.totalCostIndex < row.length) {
          total = double.tryParse(row[mapping.totalCostIndex].toString().trim()) ?? 0.0;
        }

        // Auto-reconcile 2-of-3 if one is missing
        if (total <= 0 && quantity > 0 && price > 0) {
          total = quantity * price;
        } else if (quantity <= 0 && total > 0 && price > 0) {
          quantity = total / price;
        } else if (price <= 0 && total > 0 && quantity > 0) {
          price = total / quantity;
        }

        if (total <= 0 && quantity <= 0) {
          skippedCount++;
          errors.add('Row $r: missing both quantity and total cost');
          continue;
        }

        // Optional station & notes
        String? stationName;
        if (mapping.stationIndex != null && mapping.stationIndex! < row.length) {
          final s = row[mapping.stationIndex!].toString().trim();
          if (s.isNotEmpty) stationName = s;
        }

        String? notes;
        if (mapping.notesIndex != null && mapping.notesIndex! < row.length) {
          final n = row[mapping.notesIndex!].toString().trim();
          if (n.isNotEmpty) notes = n;
        }

        final companion = FuelEntriesCompanion.insert(
          id: _uuid.v4(),
          vehicleId: vehicleId,
          entryDateTime: entryDate,
          odometer: odometer,
          quantity: quantity,
          pricePerUnit: price,
          totalCost: total,
          fuelType: defaultFuelType,
          stationName: drift.Value(stationName),
          isFullTank: const drift.Value(true),
          isMissedPrevious: const drift.Value(false),
          notes: drift.Value(notes),
        );

        await fuelRepo.saveEntry(companion);
        successCount++;
      } catch (e) {
        skippedCount++;
        errors.add('Row $r: parse error: $e');
      }
    }

    return CsvImportResult(
      successCount: successCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }
}
