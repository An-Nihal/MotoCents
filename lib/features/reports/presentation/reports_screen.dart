import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../expenses/presentation/providers/expenses_providers.dart';
import '../../fuel/data/fuel_entries_repository.dart';
import '../../fuel/domain/mileage_calculator.dart';
import '../../service/data/services_repository.dart';
import '../data/csv_import_service.dart';
import 'providers/reports_providers.dart';
import 'widgets/csv_column_mapping_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedVehicleId;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehiclesAsync = ref.watch(activeVehiclesStreamProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Data'),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No vehicles found',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a vehicle first to view reports and export data.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final effectiveVehicleId = _selectedVehicleId ?? currentVehicle?.id ?? vehicles.first.id;
          final selectedVehicle = vehicles.firstWhere(
            (v) => v.id == effectiveVehicleId,
            orElse: () => vehicles.first,
          );

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle Selector
                  _buildVehicleSelectorCard(theme, vehicles, selectedVehicle),
                  const SizedBox(height: 16),

                  // Section 1: Vehicle History PDF Report
                  _buildPdfReportCard(theme, selectedVehicle),
                  const SizedBox(height: 16),

                  // Section 2: Data Export (Excel & CSV)
                  _buildDataExportCard(theme, selectedVehicle),
                  const SizedBox(height: 16),

                  // Section 3: Data Import (CSV)
                  _buildDataImportCard(theme, selectedVehicle),
                  const SizedBox(height: 32),
                ],
              ),
              if (_isExporting)
                Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildVehicleSelectorCard(
    ThemeData theme,
    List<VehicleData> vehicles,
    VehicleData current,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Vehicle for Report',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: current.id,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: vehicles.map((v) {
                final parts = <String>[];
                if (v.make != null && v.make!.isNotEmpty) parts.add(v.make!);
                if (v.model != null && v.model!.isNotEmpty) parts.add(v.model!);
                if (v.plateNumber.isNotEmpty) parts.add(v.plateNumber);
                final subtitle = parts.join(' • ');
                return DropdownMenuItem<String>(
                  value: v.id,
                  child: Text(
                    '${v.name}${subtitle.isNotEmpty ? " ($subtitle)" : ""}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  setState(() => _selectedVehicleId = newId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfReportCard(ThemeData theme, VehicleData vehicle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle History Report',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Professional buyer-ready PDF document',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Generates a comprehensive dossier including vehicle specs, lifetime total cost of ownership (TCO), fuel efficiency metrics, full service log, and all logged expenses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePdfAction(vehicle, isPrint: true),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('View / Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handlePdfAction(vehicle, isPrint: false),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share PDF'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataExportCard(ThemeData theme, VehicleData vehicle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spreadsheet Export',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Excel workbook & RFC 4180 CSV files',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Export raw logs for external spreadsheet software, tax filing, or accounting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Excel export button
            FilledButton.tonalIcon(
              onPressed: () => _exportExcel(vehicle),
              icon: const Icon(Icons.file_download, size: 18),
              label: const Text('Export Complete Excel Workbook (.xlsx)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Text(
              'Individual CSV Exports',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.local_gas_station, size: 16),
                  label: const Text('Fuel Logs (CSV)'),
                  onPressed: () => _exportCsv(vehicle, 'fuel'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.build, size: 16),
                  label: const Text('Service History (CSV)'),
                  onPressed: () => _exportCsv(vehicle, 'service'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Other Expenses (CSV)'),
                  onPressed: () => _exportCsv(vehicle, 'expenses'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataImportCard(ThemeData theme, VehicleData vehicle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Data',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Import fill-ups from other apps or CSV files',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Select any CSV file containing your past fuel logs. Our smart column mapper will automatically detect the columns with live preview and missing value reconciliation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _importFuelCsv(vehicle),
              icon: const Icon(Icons.file_upload, size: 18),
              label: const Text('Import Fuel Logs from CSV'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions ---

  Future<void> _handlePdfAction(VehicleData vehicle, {required bool isPrint}) async {
    setState(() => _isExporting = true);
    try {
      final fuelRepo = ref.read(fuelEntriesRepositoryProvider);
      final serviceRepo = ref.read(servicesRepositoryProvider);
      final expenseRepo = ref.read(expensesRepositoryProvider);
      final pdfService = ref.read(pdfReportServiceProvider);
      final currency = ref.read(settingsProvider).currency;

      final fuelEntries = await fuelRepo.watchFuelEntriesForVehicle(vehicle.id).first;
      final statsMap = MileageCalculator.calculateAllEntriesStats(
        entries: fuelEntries,
        economyUnit: vehicle.economyUnit,
      );
      final serviceEntries = await serviceRepo.watchServiceEntriesForVehicle(vehicle.id).first;
      final expenses = await expenseRepo.watchExpenses(vehicleId: vehicle.id).first;

      final pdfBytes = await pdfService.generateVehicleHistoryPdf(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        statsMap: statsMap,
        serviceEntries: serviceEntries,
        expenses: expenses,
        currency: currency,
      );

      final cleanName = vehicle.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'Vehicle_History_$cleanName.pdf';

      if (isPrint) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
      } else {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel(VehicleData vehicle) async {
    setState(() => _isExporting = true);
    try {
      final fuelRepo = ref.read(fuelEntriesRepositoryProvider);
      final serviceRepo = ref.read(servicesRepositoryProvider);
      final expenseRepo = ref.read(expensesRepositoryProvider);
      final exportService = ref.read(dataExportServiceProvider);
      final currency = ref.read(settingsProvider).currency;

      final fuelEntries = await fuelRepo.watchFuelEntriesForVehicle(vehicle.id).first;
      final statsMap = MileageCalculator.calculateAllEntriesStats(
        entries: fuelEntries,
        economyUnit: vehicle.economyUnit,
      );
      final serviceEntries = await serviceRepo.watchServiceEntriesForVehicle(vehicle.id).first;
      final expenses = await expenseRepo.watchExpenses(vehicleId: vehicle.id).first;

      final excelBytes = exportService.exportAllToExcel(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        statsMap: statsMap,
        serviceEntries: serviceEntries,
        expenses: expenses,
        currency: currency,
      );

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final cleanName = vehicle.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${tempDir.path}/FSL_${cleanName}_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excelBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'Fuel & Service Log Export for ${vehicle.name}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel workbook: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv(VehicleData vehicle, String type) async {
    setState(() => _isExporting = true);
    try {
      final fuelRepo = ref.read(fuelEntriesRepositoryProvider);
      final serviceRepo = ref.read(servicesRepositoryProvider);
      final expenseRepo = ref.read(expensesRepositoryProvider);
      final exportService = ref.read(dataExportServiceProvider);
      final currency = ref.read(settingsProvider).currency;

      String csvContent = '';
      String filePrefix = 'Export';

      if (type == 'fuel') {
        final fuelEntries = await fuelRepo.watchFuelEntriesForVehicle(vehicle.id).first;
        final statsMap = MileageCalculator.calculateAllEntriesStats(
          entries: fuelEntries,
          economyUnit: vehicle.economyUnit,
        );
        csvContent = exportService.exportFuelLogsToCsv(
          entries: fuelEntries,
          statsMap: statsMap,
          volumeUnit: vehicle.volumeUnit,
          distanceUnit: vehicle.distanceUnit,
          currency: currency,
        );
        filePrefix = 'Fuel_Logs';
      } else if (type == 'service') {
        final serviceEntries = await serviceRepo.watchServiceEntriesForVehicle(vehicle.id).first;
        csvContent = exportService.exportServiceEntriesToCsv(
          entries: serviceEntries,
          distanceUnit: vehicle.distanceUnit,
          currency: currency,
        );
        filePrefix = 'Service_History';
      } else if (type == 'expenses') {
        final expenses = await expenseRepo.watchExpenses(vehicleId: vehicle.id).first;
        csvContent = exportService.exportExpensesToCsv(
          expenses: expenses,
          currency: currency,
        );
        filePrefix = 'Expenses';
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final cleanName = vehicle.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${tempDir.path}/${filePrefix}_${cleanName}_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'text/csv')],
          text: 'Fuel & Service Log $filePrefix for ${vehicle.name}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importFuelCsv(VehicleData vehicle) async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (pickedFile == null) return;
      String? csvContent;

      if (pickedFile.path != null) {
        csvContent = await File(pickedFile.path!).readAsString();
      } else {
        final bytes = await pickedFile.readAsBytes();
        csvContent = utf8.decode(bytes);
      }

      if (csvContent.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The selected CSV file is empty.')),
          );
        }
        return;
      }

      final importService = ref.read(csvImportServiceProvider);
      final preview = importService.parseCsvPreview(csvContent);

      if (preview.headers.isEmpty || preview.totalDataRowCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tabular data rows found in CSV.')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show Mapping Dialog
      final selectedMapping = await showDialog<CsvColumnMapping>(
        context: context,
        builder: (ctx) => CsvColumnMappingDialog(preview: preview),
      );

      if (selectedMapping == null) return;

      setState(() => _isExporting = true);

      final importResult = await importService.importFuelEntries(
        csvContent: csvContent,
        vehicleId: vehicle.id,
        defaultFuelType: vehicle.fuelType,
        mapping: selectedMapping,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  importResult.successCount > 0 ? Icons.check_circle : Icons.warning,
                  color: importResult.successCount > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                const Text('Import Finished'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully imported: ${importResult.successCount} entries'),
                if (importResult.skippedCount > 0)
                  Text('Skipped / Invalid rows: ${importResult.skippedCount}'),
                if (importResult.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${importResult.errors.take(3).join('\n')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
