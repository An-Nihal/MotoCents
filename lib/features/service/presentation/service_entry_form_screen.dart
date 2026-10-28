import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/services_repository.dart';

class ServiceItemDraft {
  String id;
  String serviceTypeId;
  String? customTypeName;
  double cost;
  String? partsUsed;
  String? notes;

  ServiceItemDraft({
    required this.id,
    required this.serviceTypeId,
    this.customTypeName,
    this.cost = 0.0,
    this.partsUsed,
    this.notes,
  });
}

class ServiceEntryFormScreen extends ConsumerStatefulWidget {
  final VehicleData vehicle;
  final ServiceEntryWithItems? entryToEdit;

  const ServiceEntryFormScreen({
    super.key,
    required this.vehicle,
    this.entryToEdit,
  });

  @override
  ConsumerState<ServiceEntryFormScreen> createState() =>
      _ServiceEntryFormScreenState();
}

class _ServiceEntryFormScreenState
    extends ConsumerState<ServiceEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late DateTime _selectedDate;
  late TextEditingController _odometerController;
  late TextEditingController _garageController;
  late TextEditingController _mechanicController;
  late TextEditingController _laborCostController;
  late TextEditingController _totalCostController;
  late TextEditingController _notesController;

  String? _receiptPath;
  bool _isSaving = false;
  final List<ServiceItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;

    _selectedDate = edit?.entry.serviceDate ?? DateTime.now();
    _odometerController = TextEditingController(
      text: edit?.entry.odometer.toStringAsFixed(0) ?? '',
    );
    _garageController =
        TextEditingController(text: edit?.entry.garageName ?? '');
    _mechanicController =
        TextEditingController(text: edit?.entry.mechanicName ?? '');
    _laborCostController = TextEditingController(
      text: edit?.entry.laborCost.toStringAsFixed(2) ?? '0.00',
    );
    _totalCostController = TextEditingController(
      text: edit?.entry.totalCost.toStringAsFixed(2) ?? '0.00',
    );
    _notesController = TextEditingController(text: edit?.entry.notes ?? '');
    _receiptPath = edit?.entry.receiptPath;

    if (edit != null) {
      for (final i in edit.items) {
        _items.add(ServiceItemDraft(
          id: i.id,
          serviceTypeId: i.serviceTypeId,
          customTypeName: i.customTypeName,
          cost: i.cost,
          partsUsed: i.partsUsed,
          notes: i.notes,
        ));
      }
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _garageController.dispose();
    _mechanicController.dispose();
    _laborCostController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    final labor = double.tryParse(_laborCostController.text) ?? 0.0;
    final itemsSum = _items.fold<double>(0.0, (sum, i) => sum + i.cost);
    final total = itemsSum + labor;
    _totalCostController.text = total.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _receiptPath = picked.path);
    }
  }

  void _addOrEditItem({ServiceItemDraft? existingItem, int? index}) {
    final availableTypes =
        ref.read(servicesRepositoryProvider).watchServiceTypes();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String selectedTypeId = existingItem?.serviceTypeId ?? '';
        final costCtrl = TextEditingController(
            text: existingItem?.cost.toStringAsFixed(2) ?? '');
        final partsCtrl =
            TextEditingController(text: existingItem?.partsUsed ?? '');
        final notesCtrl =
            TextEditingController(text: existingItem?.notes ?? '');

        return StreamBuilder<List<ServiceTypeData>>(
          stream: availableTypes,
          builder: (context, snapshot) {
            final types = snapshot.data ?? [];
            if (types.isNotEmpty && selectedTypeId.isEmpty) {
              selectedTypeId = types.first.id;
            }

            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingItem != null
                              ? 'Edit Service Item'
                              : 'Add Service Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTypeId.isNotEmpty ? selectedTypeId : null,
                          decoration: const InputDecoration(
                            labelText: 'Service Type *',
                            prefixIcon: Icon(Icons.build_rounded),
                          ),
                          items: types.map((t) {
                            return DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedTypeId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Item Cost',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: partsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Parts / Brand Used',
                            hintText: 'e.g. Mobil 1 5W-30, Bosch filter',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText: 'e.g. Cleaned housing, inspected valve',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondaryTeal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (selectedTypeId.isEmpty) return;
                              final itemCost =
                                  double.tryParse(costCtrl.text.trim()) ?? 0.0;

                              setState(() {
                                if (existingItem != null && index != null) {
                                  _items[index] = ServiceItemDraft(
                                    id: existingItem.id,
                                    serviceTypeId: selectedTypeId,
                                    cost: itemCost,
                                    partsUsed: partsCtrl.text.trim(),
                                    notes: notesCtrl.text.trim(),
                                  );
                                } else {
                                  _items.add(ServiceItemDraft(
                                    id: _uuid.v4(),
                                    serviceTypeId: selectedTypeId,
                                    cost: itemCost,
                                    partsUsed: partsCtrl.text.trim(),
                                    notes: notesCtrl.text.trim(),
                                  ));
                                }
                                _recalculateTotal();
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Save Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(servicesRepositoryProvider);
    final now = DateTime.now();

    final isEdit = widget.entryToEdit != null;
    final entryId = isEdit ? widget.entryToEdit!.entry.id : _uuid.v4();

    final odo = double.parse(_odometerController.text.trim());
    final labor = double.tryParse(_laborCostController.text.trim()) ?? 0.0;
    final total = double.parse(_totalCostController.text.trim());

    final entryCompanion = ServiceEntriesCompanion(
      id: drift.Value(entryId),
      vehicleId: drift.Value(widget.vehicle.id),
      serviceDate: drift.Value(_selectedDate),
      odometer: drift.Value(odo),
      laborCost: drift.Value(labor),
      totalCost: drift.Value(total),
      garageName: drift.Value(
        _garageController.text.trim().isEmpty
            ? null
            : _garageController.text.trim(),
      ),
      mechanicName: drift.Value(
        _mechanicController.text.trim().isEmpty
            ? null
            : _mechanicController.text.trim(),
      ),
      notes: drift.Value(
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
      receiptPath: drift.Value(_receiptPath),
      updatedAt: drift.Value(now),
    );

    final List<ServiceItemsCompanion> itemsCompanions = _items.map((i) {
      return ServiceItemsCompanion(
        id: drift.Value(i.id),
        serviceEntryId: drift.Value(entryId),
        serviceTypeId: drift.Value(i.serviceTypeId),
        customTypeName: drift.Value(i.customTypeName),
        cost: drift.Value(i.cost),
        partsUsed: drift.Value(i.partsUsed),
        notes: drift.Value(i.notes),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
    }).toList();

    await repo.saveServiceEntry(
      entry: isEdit
          ? entryCompanion
          : entryCompanion.copyWith(createdAt: drift.Value(now)),
      items: itemsCompanions,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entryToEdit != null;
    final settings = ref.watch(settingsProvider);
    final availableTypes =
        ref.watch(servicesRepositoryProvider).watchServiceTypes();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Service Entry' : 'Log Maintenance'),
        actions: [
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
                      color: AppColors.secondaryTeal,
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
            // Vehicle & Date Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            size: 18, color: AppColors.secondaryTeal),
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
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Odometer Reading
            TextFormField(
              controller: _odometerController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Odometer Reading (${widget.vehicle.distanceUnit}) *',
                hintText: 'e.g. 18500',
                prefixIcon: const Icon(Icons.speed_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter current odometer';
                }
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Garage & Mechanic Name Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _garageController,
                    decoration: const InputDecoration(
                      labelText: 'Garage / Workshop',
                      hintText: 'e.g. Navana Service',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mechanicController,
                    decoration: const InputDecoration(
                      labelText: 'Mechanic Name',
                      hintText: 'e.g. Jamal',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Service Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Items *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditItem(),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<ServiceTypeData>>(
              stream: availableTypes,
              builder: (context, snapshot) {
                final types = snapshot.data ?? [];
                final typeMap = {for (var t in types) t.id: t.name};

                if (_items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.build_circle_outlined,
                              size: 40, color: Theme.of(context).hintColor),
                          const SizedBox(height: 8),
                          Text(
                            'No items added yet',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Add Item" above to add oil, filters, brake pads, etc.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final typeName = typeMap[item.serviceTypeId] ?? 'Service Item';

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.secondaryTeal.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.build_rounded,
                            size: 18,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                        title: Text(
                          typeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.partsUsed != null && item.partsUsed!.isNotEmpty
                              ? '${item.partsUsed} • ${settings.currencySymbol}${item.cost.toStringAsFixed(2)}'
                              : '${settings.currencySymbol}${item.cost.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _addOrEditItem(
                                  existingItem: item, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(index);
                                  _recalculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Cost Summary: Labor Cost & Total Cost
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _laborCostController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _recalculateTotal(),
                    decoration: InputDecoration(
                      labelText: 'Labour Cost',
                      prefixText: '${settings.currencySymbol} ',
                      prefixIcon: const Icon(Icons.handyman_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalCostController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total Cost *',
                      prefixText: '${settings.currencySymbol} ',
                      helperText: 'Auto-calculated sum',
                      prefixIcon:
                          const Icon(Icons.account_balance_wallet_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final n = double.tryParse(val);
                      if (n == null || n < 0) return 'Must be >= 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g. Next inspection recommended in 5,000 km',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Photo Attachment
            Row(
              children: [
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
                        ? 'Receipt Attached'
                        : 'Attach Receipt Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_receiptPath != null) ...[
                  const SizedBox(width: 8),
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
                isEdit ? 'Update Service Record' : 'Save Service Record',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
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
