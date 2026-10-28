import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/services_repository.dart';

class ServiceReminderFormScreen extends ConsumerStatefulWidget {
  final VehicleData vehicle;
  final ServiceReminderData? reminderToEdit;

  const ServiceReminderFormScreen({
    super.key,
    required this.vehicle,
    this.reminderToEdit,
  });

  @override
  ConsumerState<ServiceReminderFormScreen> createState() =>
      _ServiceReminderFormScreenState();
}

class _ServiceReminderFormScreenState
    extends ConsumerState<ServiceReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String? _selectedTypeId;
  String _reminderType = 'both'; // 'distance', 'time', 'both'

  late TextEditingController _distanceIntervalController;
  late TextEditingController _monthIntervalController;
  late TextEditingController _lastOdometerController;
  late DateTime _lastServiceDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;

    _selectedTypeId = r?.serviceTypeId;
    _reminderType = r?.reminderType ?? 'both';
    _distanceIntervalController = TextEditingController(
      text: r?.intervalDistance?.toStringAsFixed(0) ?? '3000',
    );
    _monthIntervalController = TextEditingController(
      text: r?.intervalMonths?.toString() ?? '3',
    );
    _lastOdometerController = TextEditingController(
      text: r?.lastServiceOdometer?.toStringAsFixed(0) ??
          widget.vehicle.initialOdometer.toStringAsFixed(0),
    );
    _lastServiceDate = r?.lastServiceDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _distanceIntervalController.dispose();
    _monthIntervalController.dispose();
    _lastOdometerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _lastServiceDate = date);
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(servicesRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);
    final now = DateTime.now();

    final isEdit = widget.reminderToEdit != null;
    final reminderId = isEdit ? widget.reminderToEdit!.id : _uuid.v4();

    final lastOdo =
        double.tryParse(_lastOdometerController.text.trim()) ?? 0.0;
    final intervalDist =
        double.tryParse(_distanceIntervalController.text.trim());
    final intervalMonths = int.tryParse(_monthIntervalController.text.trim());

    double? dueOdo;
    DateTime? dueDate;

    if ((_reminderType == 'distance' || _reminderType == 'both') &&
        intervalDist != null) {
      dueOdo = lastOdo + intervalDist;
    }

    if ((_reminderType == 'time' || _reminderType == 'both') &&
        intervalMonths != null) {
      dueDate = DateTime(
        _lastServiceDate.year,
        _lastServiceDate.month + intervalMonths,
        _lastServiceDate.day,
      );
    }

    final notifId = reminderId.hashCode.abs() % 100000;

    final companion = ServiceRemindersCompanion(
      id: drift.Value(reminderId),
      vehicleId: drift.Value(widget.vehicle.id),
      serviceTypeId: drift.Value(_selectedTypeId!),
      reminderType: drift.Value(_reminderType),
      intervalDistance: drift.Value(intervalDist),
      intervalMonths: drift.Value(intervalMonths),
      lastServiceOdometer: drift.Value(lastOdo),
      lastServiceDate: drift.Value(_lastServiceDate),
      dueOdometer: drift.Value(dueOdo),
      dueDate: drift.Value(dueDate),
      isDismissed: const drift.Value(false),
      notificationId: drift.Value(notifId),
      updatedAt: drift.Value(now),
    );

    await repo.saveReminder(
      isEdit ? companion : companion.copyWith(createdAt: drift.Value(now)),
    );

    // Schedule notification if dueDate exists
    if (dueDate != null) {
      // Schedule reminder 7 days before due date
      final reminderDate = dueDate.subtract(const Duration(days: 7));
      if (reminderDate.isAfter(DateTime.now())) {
        await notifications.scheduleNotification(
          id: notifId,
          title: 'Service Due Soon: ${widget.vehicle.name}',
          body: 'Maintenance is due on ${DateFormat('dd MMM yyyy').format(dueDate)}.',
          scheduledDate: reminderDate,
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTypes =
        ref.watch(servicesRepositoryProvider).watchServiceTypes();
    final isEdit = widget.reminderToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Service Reminder' : 'Set Service Reminder'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveReminder,
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
            // Service Type Selector
            StreamBuilder<List<ServiceTypeData>>(
              stream: availableTypes,
              builder: (context, snapshot) {
                final types = snapshot.data ?? [];
                if (types.isNotEmpty && _selectedTypeId == null) {
                  _selectedTypeId = types.first.id;
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedTypeId,
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
                      setState(() {
                        _selectedTypeId = val;
                        // Pre-populate intervals if available
                        final matched = types.where((t) => t.id == val).firstOrNull;
                        if (matched?.defaultDistanceInterval != null) {
                          _distanceIntervalController.text = matched!
                              .defaultDistanceInterval!
                              .toStringAsFixed(0);
                        }
                        if (matched?.defaultMonthInterval != null) {
                          _monthIntervalController.text =
                              matched!.defaultMonthInterval.toString();
                        }
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Reminder Type Segmented Control
            const Text(
              'Remind Me By',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'both',
                  label: Text('Whichever 1st'),
                  icon: Icon(Icons.compare_arrows_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'distance',
                  label: Text('Distance'),
                  icon: Icon(Icons.speed_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'time',
                  label: Text('Time'),
                  icon: Icon(Icons.calendar_month_rounded, size: 16),
                ),
              ],
              selected: {_reminderType},
              onSelectionChanged: (s) {
                setState(() => _reminderType = s.first);
              },
            ),
            const SizedBox(height: 20),

            // Distance Interval Field
            if (_reminderType == 'distance' || _reminderType == 'both') ...[
              TextFormField(
                controller: _distanceIntervalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Distance Interval (${widget.vehicle.distanceUnit}) *',
                  hintText: 'e.g. 3000',
                  helperText: 'Remind every X ${widget.vehicle.distanceUnit}',
                  prefixIcon: const Icon(Icons.add_road_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Time Interval Field
            if (_reminderType == 'time' || _reminderType == 'both') ...[
              TextFormField(
                controller: _monthIntervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time Interval (Months) *',
                  hintText: 'e.g. 3',
                  helperText: 'Remind every X months',
                  prefixIcon: Icon(Icons.timelapse_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final n = int.tryParse(val);
                  if (n == null || n <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Baseline: Last Service Odometer & Date
            const Text(
              'Last Performed Baseline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lastOdometerController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Last Odometer (${widget.vehicle.distanceUnit})',
                      prefixIcon: const Icon(Icons.speed_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
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
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_lastServiceDate),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Reminder Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveReminder,
              icon: const Icon(Icons.notification_add_rounded),
              label: Text(
                isEdit ? 'Update Reminder' : 'Set Reminder',
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
          ],
        ),
      ),
    );
  }
}
