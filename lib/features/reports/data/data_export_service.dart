import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../fuel/domain/mileage_calculator.dart';
import '../../service/data/services_repository.dart';

class DataExportService {
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Exports fuel fill-up logs to a standard RFC 4180 CSV string.
  String exportFuelLogsToCsv({
    required List<FuelEntryData> entries,
    required Map<String, CalculatedEntryStats> statsMap,
    String volumeUnit = 'L',
    String distanceUnit = 'km',
    String currency = 'BDT',
  }) {
    final List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Date & Time',
      'Odometer ($distanceUnit)',
      'Quantity ($volumeUnit)',
      'Price Per Unit ($currency)',
      'Total Cost ($currency)',
      'Calculated Mileage',
      'Fuel Type',
      'Station Name',
      'Full Tank',
      'Missed Previous',
      'Notes',
    ]);

    for (final e in entries) {
      final stats = statsMap[e.id];
      final mileageStr = stats?.calculatedMileage != null
          ? stats!.calculatedMileage!.toStringAsFixed(2)
          : '';

      rows.add([
        _dateFormat.format(e.entryDateTime),
        e.odometer.toStringAsFixed(0),
        e.quantity.toStringAsFixed(2),
        e.pricePerUnit.toStringAsFixed(2),
        e.totalCost.toStringAsFixed(2),
        mileageStr,
        e.fuelType,
        e.stationName ?? '',
        e.isFullTank ? 'Yes' : 'No',
        e.isMissedPrevious ? 'Yes' : 'No',
        e.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports maintenance service entries to CSV.
  String exportServiceEntriesToCsv({
    required List<ServiceEntryWithItems> entries,
    String distanceUnit = 'km',
    String currency = 'BDT',
  }) {
    final List<List<dynamic>> rows = [];

    rows.add([
      'Service Date',
      'Odometer ($distanceUnit)',
      'Services Performed',
      'Labor Cost ($currency)',
      'Total Cost ($currency)',
      'Garage / Mechanic',
      'Notes',
    ]);

    for (final item in entries) {
      final e = item.entry;
      final servicesList = item.itemTypes.map((t) => t.name).join('; ');

      rows.add([
        DateFormat('yyyy-MM-dd').format(e.serviceDate),
        e.odometer.toStringAsFixed(0),
        servicesList,
        e.laborCost.toStringAsFixed(2),
        e.totalCost.toStringAsFixed(2),
        e.garageName ?? '',
        e.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports general other expenses to CSV.
  String exportExpensesToCsv({
    required List<ExpenseWithDetails> expenses,
    String currency = 'BDT',
  }) {
    final List<List<dynamic>> rows = [];

    rows.add([
      'Date',
      'Category',
      'Amount ($currency)',
      'Odometer',
      'Notes',
    ]);

    for (final item in expenses) {
      final e = item.expense;
      rows.add([
        DateFormat('yyyy-MM-dd').format(e.date),
        item.category.name,
        e.amount.toStringAsFixed(2),
        e.odometer != null ? e.odometer!.toStringAsFixed(0) : '',
        e.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports a complete multi-sheet Excel workbook containing Fuel, Service, and Expenses.
  Uint8List exportAllToExcel({
    required VehicleData vehicle,
    required List<FuelEntryData> fuelEntries,
    required Map<String, CalculatedEntryStats> statsMap,
    required List<ServiceEntryWithItems> serviceEntries,
    required List<ExpenseWithDetails> expenses,
    String currency = 'BDT',
  }) {
    final excel = Excel.createExcel();

    // 1. Fuel Sheet
    final fuelSheet = excel['Fuel Log'];
    fuelSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Odometer (${vehicle.distanceUnit})'),
      TextCellValue('Quantity (${vehicle.volumeUnit})'),
      TextCellValue('Price ($currency)'),
      TextCellValue('Total Cost ($currency)'),
      TextCellValue('Mileage (${vehicle.economyUnit})'),
      TextCellValue('Station'),
      TextCellValue('Notes'),
    ]);

    for (final f in fuelEntries) {
      final stats = statsMap[f.id];
      fuelSheet.appendRow([
        TextCellValue(_dateFormat.format(f.entryDateTime)),
        DoubleCellValue(f.odometer),
        DoubleCellValue(f.quantity),
        DoubleCellValue(f.pricePerUnit),
        DoubleCellValue(f.totalCost),
        stats?.calculatedMileage != null
            ? DoubleCellValue(stats!.calculatedMileage!)
            : TextCellValue('—'),
        TextCellValue(f.stationName ?? ''),
        TextCellValue(f.notes ?? ''),
      ]);
    }

    // 2. Service Sheet
    final serviceSheet = excel['Service Log'];
    serviceSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Odometer (${vehicle.distanceUnit})'),
      TextCellValue('Maintenance Items'),
      TextCellValue('Labor Cost ($currency)'),
      TextCellValue('Total Cost ($currency)'),
      TextCellValue('Garage / Center'),
      TextCellValue('Notes'),
    ]);

    for (final s in serviceEntries) {
      final itemsStr = s.itemTypes.map((t) => t.name).join(', ');
      serviceSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(s.entry.serviceDate)),
        DoubleCellValue(s.entry.odometer),
        TextCellValue(itemsStr),
        DoubleCellValue(s.entry.laborCost),
        DoubleCellValue(s.entry.totalCost),
        TextCellValue(s.entry.garageName ?? ''),
        TextCellValue(s.entry.notes ?? ''),
      ]);
    }

    // 3. Expenses Sheet
    final expenseSheet = excel['Other Expenses'];
    expenseSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Amount ($currency)'),
      TextCellValue('Odometer'),
      TextCellValue('Notes'),
    ]);

    for (final x in expenses) {
      expenseSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(x.expense.date)),
        TextCellValue(x.category.name),
        DoubleCellValue(x.expense.amount),
        x.expense.odometer != null ? DoubleCellValue(x.expense.odometer!) : TextCellValue(''),
        TextCellValue(x.expense.notes ?? ''),
      ]);
    }

    // Remove default Sheet1
    excel.delete('Sheet1');

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes ?? []);
  }
}
