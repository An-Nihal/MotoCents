import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../ocr/presentation/ocr_scanner_sheet.dart';
import '../data/fuel_entries_repository.dart';
import '../domain/fuel_entry_auto_calc.dart';

class FuelEntryFormScreen extends ConsumerStatefulWidget {
  final VehicleData vehicle;
  final FuelEntryData? entryToEdit;

  const FuelEntryFormScreen({
    super.key,
    required this.vehicle,
    this.entryToEdit,
  });

  @override
  ConsumerState<FuelEntryFormScreen> createState() => _FuelEntryFormScreenState();
}

class _FuelEntryFormScreenState extends ConsumerState<FuelEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late DateTime _selectedDateTime;
  bool _useTripMeter = false;

  late TextEditingController _odometerController;
  late TextEditingController _tripController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _totalCostController;
  late TextEditingController _stationController;
  late TextEditingController _notesController;

  late String _fuelType;
  bool _isFullTank = true;
  bool _isMissedPrevious = false;
  String? _receiptPath;

  bool _isSaving = false;
  List<String> _stationSuggestions = [];
  FuelEntryData? _previousEntry;

  @override
  void initState() {
    super.initState();
    final entry = widget.entryToEdit;

    _selectedDateTime = entry?.entryDateTime ?? DateTime.now();
    _fuelType = entry?.fuelType ?? widget.vehicle.fuelType;
    _isFullTank = entry?.isFullTank ?? true;
    _isMissedPrevious = entry?.isMissedPrevious ?? false;
    _receiptPath = entry?.receiptPath;

    _odometerController = TextEditingController(
      text: entry?.odometer.toStringAsFixed(0) ?? '',
    );
    _tripController = TextEditingController(
      text: entry?.tripDistance != null
          ? entry!.tripDistance!.toStringAsFixed(1)
          : '',
    );
    _quantityController = TextEditingController(
      text: entry?.quantity.toStringAsFixed(2) ?? '',
    );
    _priceController = TextEditingController(
      text: entry?.pricePerUnit.toStringAsFixed(2) ?? '',
    );
    _totalCostController = TextEditingController(
      text: entry?.totalCost.toStringAsFixed(2) ?? '',
    );
    _stationController = TextEditingController(text: entry?.stationName ?? '');
    _notesController = TextEditingController(text: entry?.notes ?? '');

    _loadContextData();
  }

  Future<void> _loadContextData() async {
    final repo = ref.read(fuelEntriesRepositoryProvider);
    final stations = await repo.getStationNames(widget.vehicle.id);
    final prev = await repo.getLatestEntryForVehicle(widget.vehicle.id);

    if (mounted) {
      setState(() {
        _stationSuggestions = stations;
        _previousEntry = prev;
      });
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _tripController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalCostController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTripDistanceChanged(String val) {
    final trip = double.tryParse(val);
    final prevOdo = _previousEntry != null
        ? _previousEntry!.odometer
        : widget.vehicle.initialOdometer;

    if (trip != null && trip > 0) {
      final odo = FuelEntryAutoCalc.convertTripToOdometer(
        tripDistance: trip,
        previousOdometer: prevOdo,
      );
      _odometerController.text = odo.toStringAsFixed(0);
    }
  }

  void _onQuantityChanged(String val) {
    final qty = double.tryParse(val);
    final price = double.tryParse(_priceController.text);
    final total = double.tryParse(_totalCostController.text);

    if (qty != null && price != null && price > 0) {
      final computedTotal = FuelEntryAutoCalc.calculateThird(
        quantity: qty,
        pricePerUnit: price,
        target: AutoCalcTarget.totalCost,
      );
      if (computedTotal != null) {
        _totalCostController.text = computedTotal.toStringAsFixed(2);
      }
    } else if (qty != null && total != null && total > 0 && (price == null || price == 0)) {
      final computedPrice = FuelEntryAutoCalc.calculateThird(
        quantity: qty,
        totalCost: total,
        target: AutoCalcTarget.pricePerUnit,
      );
      if (computedPrice != null) {
        _priceController.text = computedPrice.toStringAsFixed(2);
      }
    }
  }

  void _onPriceChanged(String val) {
    final price = double.tryParse(val);
    final qty = double.tryParse(_quantityController.text);
    final total = double.tryParse(_totalCostController.text);

    if (price != null && qty != null && qty > 0) {
      final computedTotal = FuelEntryAutoCalc.calculateThird(
        quantity: qty,
        pricePerUnit: price,
        target: AutoCalcTarget.totalCost,
      );
      if (computedTotal != null) {
        _totalCostController.text = computedTotal.toStringAsFixed(2);
      }
    } else if (price != null && total != null && total > 0 && (qty == null || qty == 0)) {
      final computedQty = FuelEntryAutoCalc.calculateThird(
        pricePerUnit: price,
        totalCost: total,
        target: AutoCalcTarget.quantity,
      );
      if (computedQty != null) {
        _quantityController.text = computedQty.toStringAsFixed(2);
      }
    }
  }

  void _onTotalCostChanged(String val) {
    final total = double.tryParse(val);
    final price = double.tryParse(_priceController.text);
    final qty = double.tryParse(_quantityController.text);

    if (total != null && price != null && price > 0) {
      final computedQty = FuelEntryAutoCalc.calculateThird(
        pricePerUnit: price,
        totalCost: total,
        target: AutoCalcTarget.quantity,
      );
      if (computedQty != null) {
        _quantityController.text = computedQty.toStringAsFixed(2);
      }
    } else if (total != null && qty != null && qty > 0) {
      final computedPrice = FuelEntryAutoCalc.calculateThird(
        quantity: qty,
        totalCost: total,
        target: AutoCalcTarget.pricePerUnit,
      );
      if (computedPrice != null) {
        _priceController.text = computedPrice.toStringAsFixed(2);
      }
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _receiptPath = picked.path;
      });
    }
  }

  void _openOcrScanner() {
    OcrScannerSheet.show(
      context,
      onApply: (data, imagePath) {
        setState(() {
          if (data.quantity != null) {
            _quantityController.text = data.quantity!.toStringAsFixed(2);
          }
          if (data.pricePerUnit != null) {
            _priceController.text = data.pricePerUnit!.toStringAsFixed(2);
          }
          if (data.totalCost != null) {
            _totalCostController.text = data.totalCost!.toStringAsFixed(2);
          }
          if (data.odometer != null) {
            _odometerController.text = data.odometer!.toStringAsFixed(0);
          }
          if (data.stationName != null && data.stationName!.isNotEmpty) {
            _stationController.text = data.stationName!;
          }
          if (data.fuelType != null && data.fuelType!.isNotEmpty) {
            _fuelType = data.fuelType!;
          }
          if (data.date != null) {
            _selectedDateTime = data.date!;
          }
          if (imagePath != null) {
            _receiptPath = imagePath;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applied extracted values from scan'),
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final odo = double.parse(_odometerController.text.trim());
    final qty = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final total = double.parse(_totalCostController.text.trim());
    final trip = double.tryParse(_tripController.text.trim());

    final prevOdo = _previousEntry != null
        ? _previousEntry!.odometer
        : widget.vehicle.initialOdometer;

    // Check for large jump
    if (FuelEntryAutoCalc.isUnusuallyLargeJump(
      newOdometer: odo,
      previousOdometer: prevOdo,
    )) {
      final diff = odo - prevOdo;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Large Odometer Jump'),
          content: Text(
            'The distance since the previous reading (${prevOdo.toStringAsFixed(0)}) is ${diff.toStringAsFixed(0)} ${widget.vehicle.distanceUnit}. Is this odometer reading ($odo) correct?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Check again'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, correct'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(fuelEntriesRepositoryProvider);
    final now = DateTime.now();

    final isEdit = widget.entryToEdit != null;
    final entryId = isEdit ? widget.entryToEdit!.id : _uuid.v4();

    final companion = FuelEntriesCompanion(
      id: drift.Value(entryId),
      vehicleId: drift.Value(widget.vehicle.id),
      entryDateTime: drift.Value(_selectedDateTime),
      odometer: drift.Value(odo),
      tripDistance: drift.Value(trip),
      quantity: drift.Value(qty),
      pricePerUnit: drift.Value(price),
      totalCost: drift.Value(total),
      fuelType: drift.Value(_fuelType),
      stationName: drift.Value(
          _stationController.text.trim().isEmpty ? null : _stationController.text.trim()),
      isFullTank: drift.Value(_isFullTank),
      isMissedPrevious: drift.Value(_isMissedPrevious),
      notes: drift.Value(
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
      receiptPath: drift.Value(_receiptPath),
      updatedAt: drift.Value(now),
    );

    await repo.saveEntry(
      isEdit ? companion : companion.copyWith(createdAt: drift.Value(now)),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isEdit = widget.entryToEdit != null;
    final prevOdo = _previousEntry != null
        ? _previousEntry!.odometer
        : widget.vehicle.initialOdometer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Fuel Entry' : 'Log Fill-Up'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Scan Receipt / Odometer',
            onPressed: _openOcrScanner,
          ),
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryAmber,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Vehicle & Date-Time Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            size: 18, color: AppColors.primaryAmber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.vehicle.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(_selectedDateTime),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Odometer vs Trip Meter Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    _useTripMeter ? 'Enter Trip Meter' : 'Enter Total Odometer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useTripMeter = !_useTripMeter;
                    });
                  },
                  icon: Icon(
                    _useTripMeter ? Icons.swap_horiz_rounded : Icons.add_road_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _useTripMeter ? 'Use Odometer' : 'Use Trip Meter',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Odometer Input Field
            if (_useTripMeter) ...[
              TextFormField(
                controller: _tripController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onTripDistanceChanged,
                decoration: InputDecoration(
                  labelText: 'Trip Distance (${widget.vehicle.distanceUnit}) *',
                  hintText: 'e.g. 450.5',
                  helperText:
                      'Previous odometer: ${prevOdo.toStringAsFixed(0)} ${widget.vehicle.distanceUnit}',
                  prefixIcon: const Icon(Icons.add_road_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter trip distance';
                  }
                  if (double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'Trip distance must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _odometerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_useTripMeter,
              decoration: InputDecoration(
                labelText: 'Total Odometer Reading (${widget.vehicle.distanceUnit}) *',
                hintText: 'e.g. 15450',
                helperText: _useTripMeter
                    ? 'Calculated from trip distance'
                    : 'Previous reading: ${prevOdo.toStringAsFixed(0)} ${widget.vehicle.distanceUnit}',
                prefixIcon: const Icon(Icons.speed_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter odometer reading';
                }
                final odo = double.tryParse(val);
                if (odo == null) return 'Enter a valid number';
                return FuelEntryAutoCalc.validateOdometer(
                  newOdometer: odo,
                  previousOdometer: prevOdo,
                );
              },
            ),
            const SizedBox(height: 20),

            // Auto-Calc Quantity, Price, Total Cost Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onQuantityChanged,
                    decoration: InputDecoration(
                      labelText: 'Quantity (${widget.vehicle.volumeUnit}) *',
                      hintText: '35.0',
                      prefixIcon: const Icon(Icons.local_gas_station_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final n = double.tryParse(val);
                      if (n == null || n <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onPriceChanged,
                    decoration: InputDecoration(
                      labelText: 'Price / ${widget.vehicle.volumeUnit} *',
                      hintText: '130.0',
                      prefixText: '${settings.currencySymbol} ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final n = double.tryParse(val);
                      if (n == null || n <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Cost Field
            TextFormField(
              controller: _totalCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _onTotalCostChanged,
              decoration: InputDecoration(
                labelText: 'Total Cost *',
                hintText: '4550.0',
                prefixText: '${settings.currencySymbol} ',
                helperText: 'Fill any 2 fields above to auto-calculate the 3rd',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final n = double.tryParse(val);
                if (n == null || n <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Full Tank / Partial Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tank Fill State',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _isFullTank
                                  ? 'Full Tank (Calculates Mileage)'
                                  : 'Partial Fill-Up (Accumulates)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Full Tank')),
                          ButtonSegment(value: false, label: Text('Partial')),
                        ],
                        selected: {_isFullTank},
                        onSelectionChanged: (s) {
                          setState(() => _isFullTank = s.first);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Missed previous fill-up checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Missed previous fill-up',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Check if you forgot to log a fill-up before this one (mileage will be paused).',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isMissedPrevious,
                    activeColor: AppColors.primaryAmber,
                    onChanged: (val) {
                      setState(() => _isMissedPrevious = val ?? false);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Station Name with Autocomplete
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _stationController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _stationSuggestions;
                }
                return _stationSuggestions.where((s) => s
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _stationController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  onChanged: (val) => _stationController.text = val,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Station Name',
                    hintText: 'e.g. Padma Oil Tejgaon, Jamuna Oil',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g. Highway trip, Octane 95',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Photo Attachment
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openOcrScanner,
                    icon: const Icon(Icons.document_scanner_rounded, color: AppColors.primaryAmber),
                    label: const Text('Scan with OCR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: Icon(
                      _receiptPath != null
                          ? Icons.check_circle_rounded
                          : Icons.receipt_long_rounded,
                      color: _receiptPath != null ? AppColors.success : null,
                    ),
                    label: Text(_receiptPath != null
                        ? 'Attached'
                        : 'Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_receiptPath != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Remove Receipt',
                    onPressed: () => setState(() => _receiptPath = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isEdit ? 'Update Fuel Entry' : 'Save Fuel Entry',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
