import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/vehicles_provider.dart';
import '../domain/expense_category_helper.dart';
import 'providers/expenses_providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? existingExpenseId;
  final VehicleData? preselectedVehicle;

  const ExpenseFormScreen({
    super.key,
    this.existingExpenseId,
    this.preselectedVehicle,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicleId;
  String? _selectedCategoryId;
  final _amountController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Uint8List? _receiptBytes;
  String? _receiptFileName;
  String? _existingReceiptPath;

  bool _isLoading = false;
  bool _isInitialLoad = true;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.existingExpenseId != null) {
      final repo = ref.read(expensesRepositoryProvider);
      final details = await repo.getExpenseById(widget.existingExpenseId!);
      if (details != null && mounted) {
        final exp = details.expense;
        setState(() {
          _selectedVehicleId = exp.vehicleId;
          _selectedCategoryId = exp.categoryId;
          _amountController.text = exp.amount.toStringAsFixed(2);
          if (exp.odometer != null) {
            _odometerController.text = exp.odometer!.toStringAsFixed(0);
          }
          _notesController.text = exp.notes ?? '';
          _selectedDate = exp.date;
          _existingReceiptPath = exp.receiptPath;
        });
      }
    } else {
      final currentVehicle = widget.preselectedVehicle ?? ref.read(currentVehicleProvider);
      _selectedVehicleId = currentVehicle?.id;
    }

    if (mounted) {
      setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _receiptBytes = bytes;
          _receiptFileName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Capture with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Select from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickReceipt(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCustomCategoryDialog() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Expense Category'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Ferry, Driver Allowance, Detailing',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final repo = ref.read(expensesRepositoryProvider);
                final newId = await repo.createCustomCategory(name: name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() => _selectedCategoryId = newId);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expensesRepositoryProvider);
      final odometer = double.tryParse(_odometerController.text.trim());

      await repo.saveExpense(
        id: widget.existingExpenseId,
        vehicleId: _selectedVehicleId!,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        amount: amount,
        odometer: odometer,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        receiptBytes: _receiptBytes,
        receiptFileName: _receiptFileName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingExpenseId != null
                  ? 'Expense updated'
                  : 'Expense recorded successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final vehicles = ref.watch(activeVehiclesStreamProvider).asData?.value ?? [];
    final categories = ref.watch(expenseCategoriesProvider).asData?.value ?? [];
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (_isInitialLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Default category if none selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    // Default vehicle if none selected
    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      _selectedVehicleId = vehicles.first.id;
    }

    final selectedCat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final catColor = ExpenseCategoryHelper.getCategoryColor(selectedCat?.code, selectedCat?.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExpenseId != null ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle Dropdown
            if (vehicles.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle *',
                  prefixIcon: Icon(Icons.directions_car_rounded),
                  border: OutlineInputBorder(),
                ),
                items: vehicles.map((v) {
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.name} (${v.plateNumber})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVehicleId = val),
              ),
              const SizedBox(height: 16),
            ],

            // Category Selection Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense Category *',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddCustomCategoryDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Custom Category'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category Chips Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat.id == _selectedCategoryId;
                final color = ExpenseCategoryHelper.getCategoryColor(cat.code, cat.name);
                final icon = ExpenseCategoryHelper.getCategoryIcon(cat.code, cat.name);

                return ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryId = cat.id);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Amount Field Card with Vibrant Accent
            Card(
              color: catColor.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: catColor.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Amount *',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                      decoration: InputDecoration(
                        prefixText: '${settings.currencySymbol} ',
                        prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                        hintText: '0.00',
                        border: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        if (double.tryParse(val.trim()) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Picker Tile
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_rounded),
                title: const Text('Date & Time'),
                subtitle: Text(dateFormat.format(_selectedDate)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Odometer Reading Field (Optional)
            TextFormField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer Reading (${settings.distanceUnit})',
                hintText: 'Optional e.g. 15400',
                prefixIcon: const Icon(Icons.speed_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Encrypted Receipt Photo Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Encrypted Receipt Photo (Optional)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Receipt images are securely encrypted with AES-256-GCM on disk.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_receiptBytes != null) ...[
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _receiptBytes!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.65),
                            ),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            onPressed: () => setState(() {
                              _receiptBytes = null;
                              _receiptFileName = null;
                            }),
                          ),
                        ],
                      ),
                    ] else if (_existingReceiptPath != null) ...[
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          FutureBuilder<Uint8List>(
                            future: ref.read(expensesRepositoryProvider).decryptReceipt(_existingReceiptPath!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    snapshot.data!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return const SizedBox(
                                height: 180,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.65),
                            ),
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            onPressed: () => setState(() => _existingReceiptPath = null),
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _showImagePickerSheet,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Attach Receipt Photo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g. Parking at Jamuna Future Park, Gulshan toll plaza',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isLoading
                    ? 'Saving...'
                    : widget.existingExpenseId != null
                        ? 'Update Expense'
                        : 'Save Expense',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: catColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
