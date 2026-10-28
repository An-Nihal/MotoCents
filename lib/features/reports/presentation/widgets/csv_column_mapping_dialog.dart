import 'package:flutter/material.dart';
import '../../data/csv_import_service.dart';

class CsvColumnMappingDialog extends StatefulWidget {
  final CsvImportPreview preview;

  const CsvColumnMappingDialog({
    super.key,
    required this.preview,
  });

  @override
  State<CsvColumnMappingDialog> createState() => _CsvColumnMappingDialogState();
}

class _CsvColumnMappingDialogState extends State<CsvColumnMappingDialog> {
  late int _dateIndex;
  late int _odometerIndex;
  late int _quantityIndex;
  late int _priceIndex;
  late int _totalCostIndex;
  late int? _stationIndex;
  late int? _notesIndex;

  @override
  void initState() {
    super.initState();
    final m = widget.preview.detectedMapping;
    _dateIndex = m.dateIndex;
    _odometerIndex = m.odometerIndex;
    _quantityIndex = m.quantityIndex;
    _priceIndex = m.priceIndex;
    _totalCostIndex = m.totalCostIndex;
    _stationIndex = m.stationIndex;
    _notesIndex = m.notesIndex;
  }

  bool get _isValid =>
      _dateIndex >= 0 &&
      _odometerIndex >= 0 &&
      (_quantityIndex >= 0 || _totalCostIndex >= 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headers = widget.preview.headers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.table_chart, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map CSV Columns',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.preview.totalDataRowCount} data rows found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content scrollable area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sample Preview Card
                      if (widget.preview.sampleRows.isNotEmpty) ...[
                        Text(
                          'Data Preview (First ${widget.preview.sampleRows.length} rows)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              defaultColumnWidth: const IntrinsicColumnWidth(),
                              children: [
                                TableRow(
                                  children: headers
                                      .map((h) => Padding(
                                            padding: const EdgeInsets.only(right: 16, bottom: 6),
                                            child: Text(
                                              h,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                ...widget.preview.sampleRows.map(
                                  (row) => TableRow(
                                    children: List.generate(headers.length, (idx) {
                                      final val = idx < row.length ? row[idx]?.toString() ?? '' : '';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16, bottom: 4),
                                        child: Text(
                                          val,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Field Mappings
                      Text(
                        'Column Assignments',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildDropdownField(
                        label: 'Date & Time *',
                        value: _dateIndex,
                        headers: headers,
                        isRequired: true,
                        onChanged: (val) => setState(() => _dateIndex = val ?? -1),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Odometer Reading *',
                        value: _odometerIndex,
                        headers: headers,
                        isRequired: true,
                        onChanged: (val) => setState(() => _odometerIndex = val ?? -1),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Fuel Quantity (Litres / Gallons)',
                        value: _quantityIndex,
                        headers: headers,
                        isRequired: false,
                        onChanged: (val) => setState(() => _quantityIndex = val ?? -1),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Price Per Unit',
                        value: _priceIndex,
                        headers: headers,
                        isRequired: false,
                        onChanged: (val) => setState(() => _priceIndex = val ?? -1),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Total Cost',
                        value: _totalCostIndex,
                        headers: headers,
                        isRequired: false,
                        onChanged: (val) => setState(() => _totalCostIndex = val ?? -1),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Fuel Station Name',
                        value: _stationIndex ?? -1,
                        headers: headers,
                        isRequired: false,
                        onChanged: (val) => setState(() => _stationIndex = (val != null && val >= 0) ? val : null),
                      ),
                      const SizedBox(height: 10),

                      _buildDropdownField(
                        label: 'Notes / Remarks',
                        value: _notesIndex ?? -1,
                        headers: headers,
                        isRequired: false,
                        onChanged: (val) => setState(() => _notesIndex = (val != null && val >= 0) ? val : null),
                      ),
                      const SizedBox(height: 12),

                      // Reconcile info banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_fix_high, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Smart Reconciliation: If one of Quantity, Price, or Total Cost is missing, it will automatically be calculated from the other two.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isValid
                        ? () {
                            final finalMapping = CsvColumnMapping(
                              dateIndex: _dateIndex,
                              odometerIndex: _odometerIndex,
                              quantityIndex: _quantityIndex,
                              priceIndex: _priceIndex,
                              totalCostIndex: _totalCostIndex,
                              stationIndex: _stationIndex,
                              notesIndex: _notesIndex,
                            );
                            Navigator.of(context).pop(finalMapping);
                          }
                        : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required List<String> headers,
    required bool isRequired,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<int>(
      initialValue: (value >= 0 && value < headers.length) ? value : -1,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        DropdownMenuItem<int>(
          value: -1,
          child: Text(
            isRequired ? '-- Select Column --' : '-- Not in CSV / Skip --',
            style: TextStyle(
              color: isRequired ? theme.colorScheme.error : theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ...List.generate(headers.length, (idx) {
          return DropdownMenuItem<int>(
            value: idx,
            child: Text(
              'Col ${idx + 1}: ${headers[idx]}',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
