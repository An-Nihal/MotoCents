import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/core/database/app_database.dart';
import 'package:motocents/features/expenses/data/expenses_repository.dart';
import 'package:motocents/features/fuel/domain/mileage_calculator.dart';
import 'package:motocents/features/reports/data/data_export_service.dart';
import 'package:motocents/features/service/data/services_repository.dart';

void main() {
  late DataExportService exportService;

  setUp(() {
    exportService = DataExportService();
  });

  group('DataExportService', () {
    test('exportFuelLogsToCsv formats valid CSV with header and data', () {
      final entries = [
        FuelEntryData(
          id: 'f-1',
          vehicleId: 'v-1',
          entryDateTime: DateTime(2026, 5, 1, 10, 30),
          odometer: 10500,
          quantity: 40.0,
          pricePerUnit: 125.0,
          totalCost: 5000.0,
          fuelType: 'petrol',
          isFullTank: true,
          isMissedPrevious: false,
          stationName: 'Padma Oil Hub',
          notes: 'Full tank fill up',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final statsMap = {
        'f-1': const CalculatedEntryStats(
          entryId: 'f-1',
          calculatedMileage: 12.5,
          distanceSinceLast: 500.0,
          costPerKm: 10.0,
        ),
      };

      final csv = exportService.exportFuelLogsToCsv(
        entries: entries,
        statsMap: statsMap,
      );

      expect(csv, contains('Date & Time'));
      expect(csv, contains('Odometer (km)'));
      expect(csv, contains('Padma Oil Hub'));
      expect(csv, contains('12.50'));
      expect(csv, contains('5000.00'));
    });

    test('exportServiceEntriesToCsv formats maintenance records to CSV', () {
      final entries = [
        ServiceEntryWithItems(
          entry: ServiceEntryData(
            id: 's-1',
            vehicleId: 'v-1',
            serviceDate: DateTime(2026, 6, 15),
            odometer: 15000,
            laborCost: 1000.0,
            totalCost: 4500.0,
            garageName: 'AutoMech Workshop',
            notes: 'Synthetic oil replacement',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          items: const [],
          itemTypes: [
            ServiceTypeData(
              id: 'st-1',
              name: 'Engine Oil Change',
              isCustom: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      final csv = exportService.exportServiceEntriesToCsv(entries: entries);

      expect(csv, contains('Service Date'));
      expect(csv, contains('AutoMech Workshop'));
      expect(csv, contains('Engine Oil Change'));
      expect(csv, contains('4500.00'));
    });

    test('exportExpensesToCsv formats expenses to CSV', () {
      final now = DateTime.now();
      final vehicle = VehicleData(
        id: 'v-1',
        name: 'Sedan',
        vehicleType: 'car',
        fuelType: 'petrol',
        plateNumber: 'ABC-123',
        initialOdometer: 0,
        distanceUnit: 'km',
        volumeUnit: 'L',
        economyUnit: 'km/L',
        isArchived: false,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final category = ExpenseCategoryData(
        id: 'cat-1',
        name: 'Tolls & Highway',
        icon: 'toll',
        isCustom: false,
        createdAt: now,
        updatedAt: now,
      );

      final expenses = [
        ExpenseWithDetails(
          expense: ExpenseData(
            id: 'e-1',
            vehicleId: 'v-1',
            categoryId: 'cat-1',
            amount: 350.0,
            date: DateTime(2026, 7, 1),
            odometer: 16200,
            notes: 'Padma Bridge Toll',
            createdAt: now,
            updatedAt: now,
          ),
          category: category,
          vehicle: vehicle,
        ),
      ];

      final csv = exportService.exportExpensesToCsv(expenses: expenses);

      expect(csv, contains('Tolls & Highway'));
      expect(csv, contains('350.00'));
      expect(csv, contains('Padma Bridge Toll'));
    });

    test('exportAllToExcel generates non-empty multi-sheet Excel file bytes', () {
      final now = DateTime.now();
      final vehicle = VehicleData(
        id: 'v-1',
        name: 'Toyota Camry',
        vehicleType: 'car',
        fuelType: 'octane',
        plateNumber: 'DHK-5555',
        initialOdometer: 5000,
        distanceUnit: 'km',
        volumeUnit: 'L',
        economyUnit: 'km/L',
        isArchived: false,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final excelBytes = exportService.exportAllToExcel(
        vehicle: vehicle,
        fuelEntries: const [],
        statsMap: const {},
        serviceEntries: const [],
        expenses: const [],
      );

      expect(excelBytes.isNotEmpty, true);
      // Valid zip/xlsx header begins with 'PK' (0x50, 0x4B)
      expect(excelBytes[0], 0x50);
      expect(excelBytes[1], 0x4B);
    });
  });
}
