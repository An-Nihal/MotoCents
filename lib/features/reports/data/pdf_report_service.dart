import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../fuel/domain/mileage_calculator.dart';
import '../../service/data/services_repository.dart';

class PdfReportService {
  final _dateFormat = DateFormat('dd MMM yyyy');

  /// Generates a comprehensive, professional Vehicle History PDF suitable for car buyers and personal records.
  Future<Uint8List> generateVehicleHistoryPdf({
    required VehicleData vehicle,
    required List<FuelEntryData> fuelEntries,
    required Map<String, CalculatedEntryStats> statsMap,
    required List<ServiceEntryWithItems> serviceEntries,
    required List<ExpenseWithDetails> expenses,
    String currency = 'BDT',
  }) async {
    final pdf = pw.Document();

    // 1. Calculate Summary Totals
    double totalFuelCost = 0.0;
    double totalFuelVolume = 0.0;
    final List<double> mileages = [];

    for (final f in fuelEntries) {
      totalFuelCost += f.totalCost;
      totalFuelVolume += f.quantity;
      final st = statsMap[f.id];
      if (st?.calculatedMileage != null && st!.calculatedMileage! > 0) {
        mileages.add(st.calculatedMileage!);
      }
    }

    double totalServiceCost = 0.0;
    for (final s in serviceEntries) {
      totalServiceCost += s.entry.totalCost;
    }

    double totalOtherExpenses = 0.0;
    for (final x in expenses) {
      totalOtherExpenses += x.expense.amount;
    }

    final double tco = totalFuelCost + totalServiceCost + totalOtherExpenses;
    final double avgMileage = mileages.isNotEmpty
        ? mileages.reduce((a, b) => a + b) / mileages.length
        : 0.0;

    double maxOdometer = vehicle.initialOdometer;
    if (fuelEntries.isNotEmpty) {
      final fMax = fuelEntries.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
      if (fMax > maxOdometer) maxOdometer = fMax;
    }
    if (serviceEntries.isNotEmpty) {
      final sMax = serviceEntries.map((e) => e.entry.odometer).reduce((a, b) => a > b ? a : b);
      if (sMax > maxOdometer) maxOdometer = sMax;
    }
    final double totalDistanceTracked = maxOdometer - vehicle.initialOdometer;

    // Theme colors for PDF
    final primaryColor = PdfColor.fromHex('#F59E0B'); // Warm Amber
    final headerColor = PdfColor.fromHex('#1E293B');  // Slate
    final lightBg = PdfColor.fromHex('#F8FAFC');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MOTOCENTS — VEHICLE REPORT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          );
        },
        build: (pw.Context context) => [
          // Report Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    vehicle.name,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${vehicle.plateNumber} • ${vehicle.vehicleType.toUpperCase()} • ${vehicle.fuelType.toUpperCase()}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'OFFICIAL HISTORY',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Overview KPI Summary Strip
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfKpi('Current Odometer', '${maxOdometer.toStringAsFixed(0)} ${vehicle.distanceUnit}'),
                _buildPdfKpi('Tracked Distance', '${totalDistanceTracked.toStringAsFixed(0)} ${vehicle.distanceUnit}'),
                _buildPdfKpi('Avg Economy', avgMileage > 0 ? '${avgMileage.toStringAsFixed(1)} ${vehicle.economyUnit}' : '—'),
                _buildPdfKpi('Total Spend (TCO)', '$currency ${tco.toStringAsFixed(0)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Financial Breakdown Sub-row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSpendCategoryCard('Fuel Expenses', '$currency ${totalFuelCost.toStringAsFixed(0)}', '${fuelEntries.length} fill-ups (${totalFuelVolume.toStringAsFixed(0)} ${vehicle.volumeUnit})'),
              _buildSpendCategoryCard('Service & Maintenance', '$currency ${totalServiceCost.toStringAsFixed(0)}', '${serviceEntries.length} service records'),
              _buildSpendCategoryCard('Other Running Costs', '$currency ${totalOtherExpenses.toStringAsFixed(0)}', '${expenses.length} expense logs'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Section 1: Maintenance & Service History
          pw.Text(
            'MAINTENANCE & SERVICE HISTORY',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerColor),
          ),
          pw.SizedBox(height: 8),

          if (serviceEntries.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('No maintenance or service records logged yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: headerColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Odometer', 'Maintenance Items', 'Garage / Center', 'Labor', 'Total Cost'],
              data: serviceEntries.map((s) {
                final itemsStr = s.itemTypes.map((t) => t.name).join(', ');
                return [
                  _dateFormat.format(s.entry.serviceDate),
                  '${s.entry.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
                  itemsStr.isNotEmpty ? itemsStr : 'General Maintenance',
                  s.entry.garageName ?? '—',
                  '$currency ${s.entry.laborCost.toStringAsFixed(0)}',
                  '$currency ${s.entry.totalCost.toStringAsFixed(0)}',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 24),

          // Section 2: Recent Fuel Fill-Ups Summary
          pw.Text(
            'FUEL FILL-UP LOG (RECENT)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerColor),
          ),
          pw.SizedBox(height: 8),

          if (fuelEntries.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('No fuel entries logged yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: headerColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Odometer', 'Volume', 'Price', 'Total Cost', 'Economy', 'Station'],
              data: fuelEntries.take(15).map((f) {
                final st = statsMap[f.id];
                return [
                  _dateFormat.format(f.entryDateTime),
                  '${f.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
                  '${f.quantity.toStringAsFixed(1)} ${vehicle.volumeUnit}',
                  '$currency ${f.pricePerUnit.toStringAsFixed(1)}',
                  '$currency ${f.totalCost.toStringAsFixed(0)}',
                  st?.calculatedMileage != null ? '${st!.calculatedMileage!.toStringAsFixed(1)} ${vehicle.economyUnit}' : '—',
                  f.stationName ?? '—',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 24),

          // Section 3: Other Expenses Summary
          if (expenses.isNotEmpty) ...[
            pw.Text(
              'OTHER EXPENSES',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerColor),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: headerColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Category', 'Amount', 'Odometer', 'Notes'],
              data: expenses.take(10).map((x) {
                return [
                  _dateFormat.format(x.expense.date),
                  x.category.name,
                  '$currency ${x.expense.amount.toStringAsFixed(0)}',
                  x.expense.odometer != null ? '${x.expense.odometer!.toStringAsFixed(0)} ${vehicle.distanceUnit}' : '—',
                  x.expense.notes ?? '—',
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Triggers standard printing dialog or export share sheet.
  Future<void> printOrShareReport({
    required Uint8List pdfBytes,
    required String documentTitle,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: documentTitle,
    );
  }

  /// Directly shares PDF using system share sheet
  Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  pw.Widget _buildPdfKpi(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildSpendCategoryCard(String title, String amount, String subtitle) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 2),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(amount, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 1),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ],
        ),
      ),
    );
  }
}
