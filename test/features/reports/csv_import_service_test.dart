import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/core/database/app_database.dart';
import 'package:fuel_and_service_log/features/fuel/data/fuel_entries_repository.dart';
import 'package:fuel_and_service_log/features/reports/data/csv_import_service.dart';

void main() {
  late AppDatabase db;
  late FuelEntriesRepository fuelRepo;
  late CsvImportService importService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fuelRepo = FuelEntriesRepository(db);
    importService = CsvImportService(fuelRepo: fuelRepo);

    // Create a vehicle
    await db.into(db.vehicles).insert(
          VehiclesCompanion.insert(
            id: 'v-test',
            name: 'Test Vehicle',
            vehicleType: 'car',
            fuelType: 'petrol',
            plateNumber: 'TST-1234',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('CsvImportService', () {
    test('parseCsvPreview correctly identifies column indices from headers', () {
      const csv = '''Date,Odometer,Quantity,Price,Total Cost,Station,Notes
2026-05-01,12000,45,120,5400,Puma Station,First fill
2026-05-10,12450,40,120,4800,Shell Station,Second fill
''';

      final preview = importService.parseCsvPreview(csv);

      expect(preview.headers.length, 7);
      expect(preview.totalDataRowCount, 2);
      expect(preview.sampleRows.length, 2);

      final mapping = preview.detectedMapping;
      expect(mapping.dateIndex, 0);
      expect(mapping.odometerIndex, 1);
      expect(mapping.quantityIndex, 2);
      expect(mapping.priceIndex, 3);
      expect(mapping.totalCostIndex, 4);
      expect(mapping.stationIndex, 5);
      expect(mapping.notesIndex, 6);
      expect(mapping.isValid, true);
    });

    test('importFuelEntries reconciles missing price and inserts valid entries', () async {
      // Row 1: has qty and total, price missing
      // Row 2: invalid odometer -> should skip
      // Row 3: normal
      const csv = '''Date,Odometer,Volume,Rate,Amount,Pump
2026-05-01,15000,50,,6000,Meghna Fuel
2026-05-05,0,30,120,3600,Invalid Odo
2026-05-12,15600,40,120,4800,Jamuna Fuel
''';

      final preview = importService.parseCsvPreview(csv);
      final mapping = preview.detectedMapping;

      final result = await importService.importFuelEntries(
        csvContent: csv,
        vehicleId: 'v-test',
        defaultFuelType: 'petrol',
        mapping: mapping,
      );

      expect(result.successCount, 2);
      expect(result.skippedCount, 1);

      // Verify entries in database
      final entries = await db.select(db.fuelEntries).get();
      expect(entries.length, 2);

      final firstEntry = entries.firstWhere((e) => e.odometer == 15000);
      expect(firstEntry.quantity, 50.0);
      expect(firstEntry.totalCost, 6000.0);
      // Auto-reconciled price: 6000 / 50 = 120
      expect(firstEntry.pricePerUnit, 120.0);
      expect(firstEntry.stationName, 'Meghna Fuel');
    });
  });
}
