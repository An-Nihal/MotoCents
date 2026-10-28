import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/vehicles_repository.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final VehicleData? vehicleToEdit;

  const VehicleFormScreen({super.key, this.vehicleToEdit});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateController;
  late TextEditingController _tankCapacityController;
  late TextEditingController _initialOdometerController;

  String _vehicleType = 'car';
  String _fuelType = 'octane';
  String _distanceUnit = 'km';
  String _volumeUnit = 'L';
  String _economyUnit = 'km/L';
  String? _photoPath;

  bool _isSaving = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'code': 'car', 'label': 'Car', 'icon': Icons.directions_car_rounded},
    {'code': 'motorcycle', 'label': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
    {'code': 'cng', 'label': 'CNG / Auto', 'icon': Icons.electric_rickshaw_rounded},
    {'code': 'microbus', 'label': 'Microbus', 'icon': Icons.airport_shuttle_rounded},
    {'code': 'truck', 'label': 'Truck', 'icon': Icons.local_shipping_rounded},
    {'code': 'other', 'label': 'Other', 'icon': Icons.commute_rounded},
  ];

  final List<String> _fuelTypes = [
    'octane',
    'petrol',
    'diesel',
    'cng',
    'lpg',
    'electric',
    'hybrid',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _nameController = TextEditingController(text: v?.name ?? '');
    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(text: v?.year?.toString() ?? '');
    _plateController = TextEditingController(text: v?.plateNumber ?? '');
    _tankCapacityController =
        TextEditingController(text: v?.tankCapacity?.toString() ?? '');
    _initialOdometerController =
        TextEditingController(text: v?.initialOdometer.toStringAsFixed(0) ?? '0');

    if (v != null) {
      _vehicleType = v.vehicleType;
      _fuelType = v.fuelType;
      _distanceUnit = v.distanceUnit;
      _volumeUnit = v.volumeUnit;
      _economyUnit = v.economyUnit;
      _photoPath = v.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _tankCapacityController.dispose();
    _initialOdometerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(vehiclesRepositoryProvider);
    final now = DateTime.now();

    final isEdit = widget.vehicleToEdit != null;
    final vehicleId = isEdit ? widget.vehicleToEdit!.id : _uuid.v4();

    final companion = VehiclesCompanion(
      id: drift.Value(vehicleId),
      name: drift.Value(_nameController.text.trim()),
      vehicleType: drift.Value(_vehicleType),
      make: drift.Value(
          _makeController.text.trim().isEmpty ? null : _makeController.text.trim()),
      model: drift.Value(
          _modelController.text.trim().isEmpty ? null : _modelController.text.trim()),
      year: drift.Value(int.tryParse(_yearController.text.trim())),
      fuelType: drift.Value(_fuelType),
      plateNumber: drift.Value(_plateController.text.trim()),
      tankCapacity: drift.Value(double.tryParse(_tankCapacityController.text.trim())),
      initialOdometer: drift.Value(
          double.tryParse(_initialOdometerController.text.trim()) ?? 0.0),
      photoPath: drift.Value(_photoPath),
      distanceUnit: drift.Value(_distanceUnit),
      volumeUnit: drift.Value(_volumeUnit),
      economyUnit: drift.Value(_economyUnit),
      updatedAt: drift.Value(now),
    );

    if (isEdit) {
      await repo.updateVehicle(companion);
    } else {
      await repo.createVehicle(
        companion.copyWith(
          createdAt: drift.Value(now),
        ),
      );
      // Auto-select as current vehicle
      await ref.read(settingsProvider.notifier).setSelectedVehicleId(vehicleId);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.vehicleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveVehicle,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
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
            // Vehicle Photo Avatar Picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primaryAmber.withValues(alpha: 0.15),
                      backgroundImage: _photoPath != null
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? const Icon(
                              Icons.directions_car_rounded,
                              size: 48,
                              color: AppColors.primaryAmber,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryAmber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Type Selector (Horizontal Chips)
            const Text(
              'Vehicle Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _vehicleTypes.map((type) {
                  final isSelected = _vehicleType == type['code'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      avatar: Icon(
                        type['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : null,
                      ),
                      label: Text(type['label'] as String),
                      selected: isSelected,
                      selectedColor: AppColors.primaryAmber,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _vehicleType = type['code'] as String);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name *',
                hintText: 'e.g. My Civic, Red FZ-S',
                prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a name for the vehicle';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Plate / Registration Number
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration / Plate Number *',
                hintText: 'e.g. DHAKA METRO GA-11-2233',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter license plate/registration number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fuel Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _fuelType,
              decoration: const InputDecoration(
                labelText: 'Primary Fuel Type *',
                prefixIcon: Icon(Icons.local_gas_station_rounded),
              ),
              items: _fuelTypes.map((fuel) {
                return DropdownMenuItem(
                  value: fuel,
                  child: Text(fuel.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _fuelType = val);
              },
            ),
            const SizedBox(height: 16),

            // Make, Model, Year Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                      labelText: 'Make',
                      hintText: 'e.g. Toyota',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g. Corolla',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      hintText: '2022',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Initial Odometer & Tank Capacity
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _initialOdometerController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Initial Odometer',
                      suffixText: _distanceUnit,
                      prefixIcon: const Icon(Icons.speed_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tankCapacityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tank Capacity',
                      hintText: 'Optional',
                      suffixText: _volumeUnit,
                      prefixIcon: const Icon(Icons.water_drop_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Unit Preferences Section
            const Text(
              'Per-Vehicle Units',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Text('Distance Unit'),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'km', label: Text('km')),
                          ButtonSegment(value: 'mi', label: Text('miles')),
                        ],
                        selected: {_distanceUnit},
                        onSelectionChanged: (s) {
                          setState(() {
                            _distanceUnit = s.first;
                            if (_distanceUnit == 'mi' && _economyUnit == 'km/L') {
                              _economyUnit = 'MPG';
                            } else if (_distanceUnit == 'km' && _economyUnit == 'MPG') {
                              _economyUnit = 'km/L';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Volume Unit'),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'L', label: Text('Litres')),
                          ButtonSegment(value: 'gal', label: Text('Gallons')),
                        ],
                        selected: {_volumeUnit},
                        onSelectionChanged: (s) {
                          setState(() => _volumeUnit = s.first);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Economy Display'),
                      DropdownButton<String>(
                        value: _economyUnit,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'km/L', child: Text('km/L')),
                          DropdownMenuItem(value: 'L/100km', child: Text('L/100km')),
                          DropdownMenuItem(value: 'MPG', child: Text('MPG (US)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _economyUnit = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveVehicle,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isEdit ? 'Update Vehicle' : 'Save Vehicle',
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
