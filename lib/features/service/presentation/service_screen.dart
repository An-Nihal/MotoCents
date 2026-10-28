import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../garage/presentation/vehicle_form_screen.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../data/services_repository.dart';
import '../domain/reminder_calculator.dart';
import 'service_entry_form_screen.dart';
import 'service_reminder_form_screen.dart';

class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key});

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddService(BuildContext context, VehicleData vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceEntryFormScreen(vehicle: vehicle),
      ),
    );
  }

  void _openSetReminder(BuildContext context, VehicleData vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceReminderFormScreen(vehicle: vehicle),
      ),
    );
  }

  void _showAddActionSheet(BuildContext context, VehicleData vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_rounded,
                      color: AppColors.secondaryTeal),
                ),
                title: const Text('Log Maintenance Service',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Record oil change, repairs, parts, & costs'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddService(context, vehicle);
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_add_rounded,
                      color: AppColors.primaryAmber),
                ),
                title: const Text('Set Service Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text('Schedule alerts by distance, time, or both'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSetReminder(context, vehicle);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentVehicle = ref.watch(currentVehicleProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: VehicleAppBar(
        title: l10n.navService,
        actions: [
          if (currentVehicle != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add',
              onPressed: () => _showAddActionSheet(context, currentVehicle),
            ),
        ],
      ),
      floatingActionButton: currentVehicle != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddActionSheet(context, currentVehicle),
              backgroundColor: AppColors.secondaryTeal,
              icon: const Icon(Icons.build_rounded),
              label: const Text('Log Service'),
            )
          : null,
      body: currentVehicle == null
          ? _buildNoVehicleState(context, l10n)
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.secondaryTeal,
                  labelColor: AppColors.secondaryTeal,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.history_rounded),
                      text: 'Service History',
                    ),
                    Tab(
                      icon: Icon(Icons.notifications_active_outlined),
                      text: 'Reminders & Due',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(context, currentVehicle, settings),
                      _buildRemindersTab(context, currentVehicle),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoVehicleState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 64,
                color: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noVehiclesTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noVehiclesDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addFirstVehicle),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  Widget _buildHistoryTab(
    BuildContext context,
    VehicleData vehicle,
    SettingsState settings,
  ) {
    final repo = ref.watch(servicesRepositoryProvider);
    final historyStream = repo.watchServiceEntriesForVehicle(vehicle.id);

    return StreamBuilder<List<ServiceEntryWithItems>>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build_rounded,
                        size: 48, color: AppColors.secondaryTeal),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No services logged yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep track of routine oil changes, filters, repairs, and labor costs for ${vehicle.name}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openAddService(context, vehicle),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log First Service'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final itemWithEntry = list[index];
            final entry = itemWithEntry.entry;

            return Dismissible(
              key: Key(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.error,
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Service Entry?'),
                    content: const Text(
                        'Are you sure you want to remove this service record?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                repo.softDeleteServiceEntry(entry.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Service record deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primaryAmberLight,
                      onPressed: () => repo.restoreServiceEntry(entry.id),
                    ),
                  ),
                );
              },
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceEntryFormScreen(
                          vehicle: vehicle,
                          entryToEdit: itemWithEntry,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(entry.serviceDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (entry.garageName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.garageName!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${settings.currencySymbol} ${entry.totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                                Text(
                                  '${entry.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Service Item Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: itemWithEntry.itemTypes.map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTeal
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded,
                                      size: 14, color: AppColors.secondaryTeal),
                                  const SizedBox(width: 4),
                                  Text(
                                    type.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            entry.notes!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRemindersTab(
    BuildContext context,
    VehicleData vehicle,
  ) {
    final repo = ref.watch(servicesRepositoryProvider);
    final remindersStream = repo.watchRemindersForVehicle(vehicle.id);
    final typesStream = repo.watchServiceTypes();

    return StreamBuilder<List<ServiceReminderData>>(
      stream: remindersStream,
      builder: (context, remSnapshot) {
        if (remSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = remSnapshot.data ?? [];

        return StreamBuilder<List<ServiceTypeData>>(
          stream: typesStream,
          builder: (context, typeSnapshot) {
            final types = typeSnapshot.data ?? [];
            final typeMap = {for (var t in types) t.id: t.name};

            if (reminders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAmber.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alarm_on_rounded,
                            size: 48, color: AppColors.primaryAmber),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No service reminders set',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set reminders for engine oil, filters, or brake pads by distance or time.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _openSetReminder(context, vehicle),
                        icon: const Icon(Icons.alarm_add_rounded),
                        label: const Text('Set First Reminder'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 84),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final rem = reminders[index];
                final typeName = typeMap[rem.serviceTypeId] ?? 'Service';

                final progress = ReminderCalculator.calculateProgress(
                  reminderType: rem.reminderType,
                  currentOdometer: vehicle.initialOdometer,
                  lastServiceOdometer: rem.lastServiceOdometer ?? 0.0,
                  lastServiceDate: rem.lastServiceDate ?? DateTime.now(),
                  intervalDistance: rem.intervalDistance,
                  intervalMonths: rem.intervalMonths,
                );

                Color statusColor;
                switch (progress.status) {
                  case ReminderStatus.overdue:
                    statusColor = AppColors.error;
                    break;
                  case ReminderStatus.dueSoon:
                    statusColor = AppColors.warning;
                    break;
                  case ReminderStatus.ok:
                    statusColor = AppColors.secondaryTeal;
                    break;
                }

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceReminderFormScreen(
                            vehicle: vehicle,
                            reminderToEdit: rem,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.build_rounded,
                                    size: 20, color: statusColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      typeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      progress.statusDescription,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppColors.error),
                                onPressed: () => repo.deleteReminder(rem.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress.progressRatio,
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Details row: Interval / Due details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (rem.intervalDistance != null)
                                Text(
                                  'Every ${rem.intervalDistance!.toStringAsFixed(0)} ${vehicle.distanceUnit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (rem.intervalMonths != null)
                                Text(
                                  'Every ${rem.intervalMonths} months',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (progress.estimatedDueDate != null)
                                Text(
                                  'Due: ${DateFormat('dd MMM yyyy').format(progress.estimatedDueDate!)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
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
}
