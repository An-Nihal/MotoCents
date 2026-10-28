import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../documents/data/documents_repository.dart';
import '../../documents/domain/document_expiry_calculator.dart';
import '../../documents/presentation/providers/documents_providers.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/presentation/expense_form_screen.dart';
import '../../fuel/data/fuel_entries_repository.dart';
import '../../fuel/domain/fuel_unit_converter.dart';
import '../../fuel/domain/mileage_calculator.dart';
import '../../fuel/presentation/fuel_entry_form_screen.dart';
import '../../garage/presentation/vehicle_form_screen.dart';
import '../../service/data/services_repository.dart';
import '../../service/domain/reminder_calculator.dart';
import '../../service/presentation/service_entry_form_screen.dart';
import '../../service/presentation/service_reminder_form_screen.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../../smart/domain/mileage_drop_detector.dart';
import '../../smart/presentation/widgets/mileage_drop_alert_card.dart';
import '../../statistics/presentation/statistics_screen.dart';
import 'providers/home_dashboard_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentVehicle = ref.watch(currentVehicleProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: VehicleAppBar(
        title: l10n.appTitle,
      ),
      body: currentVehicle == null
          ? _buildEmptyState(context, l10n)
          : _buildDashboard(context, ref, l10n, currentVehicle, settings),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 72,
                color: AppColors.primaryAmber,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noVehiclesTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addFirstVehicle),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
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

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    VehicleData vehicle,
    SettingsState settings,
  ) {
    final fuelRepo = ref.watch(fuelEntriesRepositoryProvider);
    final serviceRepo = ref.watch(servicesRepositoryProvider);

    final fuelStream = fuelRepo.watchFuelEntriesForVehicle(vehicle.id);
    final remindersStream = serviceRepo.watchRemindersForVehicle(vehicle.id);
    final serviceTypesStream = serviceRepo.watchServiceTypes();

    return StreamBuilder<List<FuelEntryData>>(
      stream: fuelStream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        // Compute current odometer
        double currentOdometer = vehicle.initialOdometer;
        if (entries.isNotEmpty) {
          final maxEntryOdo = entries.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
          if (maxEntryOdo > currentOdometer) {
            currentOdometer = maxEntryOdo;
          }
        }

        // Compute mileage & stats
        final statsMap = MileageCalculator.calculateAllEntriesStats(
          entries: entries,
          economyUnit: vehicle.economyUnit,
        );
        final summary = MileageCalculator.calculateVehicleSummary(
          entries: entries,
          entryStats: statsMap,
          economyUnit: vehicle.economyUnit,
        );

        // Compute last valid mileage
        double? lastMileage;
        for (int i = entries.length - 1; i >= 0; i--) {
          final s = statsMap[entries[i].id];
          if (s?.calculatedMileage != null) {
            lastMileage = s!.calculatedMileage;
            break;
          }
        }

        // Compute latest mileage anomaly
        final latestAnomaly = MileageDropDetector.detectLatestAnomaly(
          entries: entries,
          entryStats: statsMap,
          economyUnit: vehicle.economyUnit,
        );

        // Combined spend this month (Fuel + Service + Other Expenses)
        final combinedSpendAsync = ref.watch(homeSpendThisMonthProvider);
        final spendThisMonth = combinedSpendAsync.asData?.value ?? 0.0;

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Stat Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: l10n.currentOdometer,
                        value:
                            '${currentOdometer.toStringAsFixed(0)} ${vehicle.distanceUnit}',
                        icon: Icons.speed_rounded,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: l10n.lastMileage,
                        value: FuelUnitConverter.formatEconomy(
                            lastMileage, vehicle.economyUnit),
                        subtitle: vehicle.economyUnit,
                        icon: Icons.local_gas_station_rounded,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: l10n.avgMileage,
                        value: FuelUnitConverter.formatEconomy(
                            summary.avgMileage, vehicle.economyUnit),
                        subtitle: vehicle.economyUnit,
                        icon: Icons.trending_up_rounded,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: l10n.spendThisMonth,
                        value:
                            '${settings.currencySymbol} ${spendThisMonth.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.deepPurpleAccent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StatisticsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Row (Fuel, Service, Expense)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FuelEntryFormScreen(vehicle: vehicle),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_gas_station_rounded, size: 16),
                        label: Text(l10n.addFuel, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceEntryFormScreen(vehicle: vehicle),
                            ),
                          );
                        },
                        icon: const Icon(Icons.build_rounded, size: 16),
                        label: Text(l10n.logService, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseFormScreen(preselectedVehicle: vehicle),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payments_rounded, size: 16),
                        label: Text(l10n.addExpense, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Statistics Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryAmber.withValues(alpha: 0.12),
                          AppColors.secondaryTeal.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryAmber.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, color: AppColors.primaryAmber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.viewStatisticsCostAnalysis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                              ),
                              Text(
                                l10n.statisticsCostAnalysisSubtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.primaryAmber, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mileage Drop Alert if detected on latest fill-up
              if (latestAnomaly != null)
                MileageDropAlertCard(alert: latestAnomaly),

              // Next Service Due Section (Live Reminders Integration)
              StreamBuilder<List<ServiceReminderData>>(
                stream: remindersStream,
                builder: (context, remSnapshot) {
                  final reminders = remSnapshot.data ?? [];

                  return StreamBuilder<List<ServiceTypeData>>(
                    stream: serviceTypesStream,
                    builder: (context, typeSnapshot) {
                      final types = typeSnapshot.data ?? [];
                      final typeMap = {for (var t in types) t.id: t.name};

                      ServiceReminderData? mostUrgentReminder;
                      ServiceReminderProgress? mostUrgentProgress;

                      if (reminders.isNotEmpty) {
                        for (final r in reminders) {
                          final prog = ReminderCalculator.calculateProgress(
                            reminderType: r.reminderType,
                            currentOdometer: currentOdometer,
                            lastServiceOdometer: r.lastServiceOdometer ?? 0.0,
                            lastServiceDate: r.lastServiceDate ?? DateTime.now(),
                            intervalDistance: r.intervalDistance,
                            intervalMonths: r.intervalMonths,
                          );

                          if (mostUrgentProgress == null ||
                              prog.rawProgressRatio >
                                  mostUrgentProgress.rawProgressRatio) {
                            mostUrgentReminder = r;
                            mostUrgentProgress = prog;
                          }
                        }
                      }

                      return Card(
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
                                      color: AppColors.secondaryTeal
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.build_circle_rounded,
                                      color: AppColors.secondaryTeal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.nextServiceDue,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ServiceReminderFormScreen(
                                                  vehicle: vehicle),
                                        ),
                                      );
                                    },
                                    child: Text(l10n.setReminder),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (mostUrgentReminder != null &&
                                  mostUrgentProgress != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      typeMap[mostUrgentReminder.serviceTypeId] ??
                                          'Service Due',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      mostUrgentProgress.statusDescription,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: mostUrgentProgress.status ==
                                                ReminderStatus.overdue
                                            ? AppColors.error
                                            : mostUrgentProgress.status ==
                                                    ReminderStatus.dueSoon
                                                ? AppColors.warning
                                                : AppColors.secondaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: mostUrgentProgress.progressRatio,
                                    minHeight: 8,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    color: mostUrgentProgress.status ==
                                            ReminderStatus.overdue
                                        ? AppColors.error
                                        : mostUrgentProgress.status ==
                                                ReminderStatus.dueSoon
                                            ? AppColors.warning
                                            : AppColors.secondaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (mostUrgentProgress.estimatedDueDate != null)
                                  Text(
                                    'Estimated: ${DateFormat('dd MMM yyyy').format(mostUrgentProgress.estimatedDueDate!)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ] else ...[
                                Text(
                                  l10n.noActiveReminders,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Documents Expiring Soon Section
              StreamBuilder<List<DocumentWithDetails>>(
                stream: ref
                    .watch(documentsRepositoryProvider)
                    .watchDocuments(vehicleId: vehicle.id),
                builder: (context, docSnapshot) {
                  final allDocs = docSnapshot.data ?? [];
                  final expiredDocs = allDocs
                      .where((d) => d.expiryStatus == DocumentExpiryStatus.expired)
                      .toList();
                  final expiringDocs = allDocs
                      .where((d) =>
                          d.expiryStatus == DocumentExpiryStatus.expiringSoon)
                      .toList();

                  final alertColor = expiredDocs.isNotEmpty
                      ? AppColors.error
                      : expiringDocs.isNotEmpty
                          ? AppColors.warning
                          : Colors.indigo;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go('/documents'),
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
                                    color: alertColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.folder_shared_rounded,
                                    color: alertColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.documentsExpiringSoon,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/documents'),
                                  child: Text(l10n.viewVault),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (expiredDocs.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      size: 16, color: AppColors.error),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${expiredDocs.length} document(s) expired!',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expiredDocs.map((d) => d.document.title).join(', '),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else if (expiringDocs.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 16, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${expiringDocs.length} document(s) expiring soon',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expiringDocs.map((d) => d.document.title).join(', '),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else ...[
                              Text(
                                allDocs.isEmpty
                                    ? 'No documents added yet. Tap to add your License & Registration.'
                                    : l10n.noExpiringDocuments,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Recent Activity Timeline
              _buildRecentActivitySection(context, ref, vehicle, settings),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    WidgetRef ref,
    VehicleData vehicle,
    SettingsState settings,
  ) {
    final activityAsync = ref.watch(homeRecentActivityProvider);

    return Card(
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
                    color: Colors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            activityAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Could not load activities: $err',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No activities logged yet for this vehicle.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  );
                }

                final dateFormat = DateFormat('dd MMM');

                return Column(
                  children: items.map((item) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        switch (item.type) {
                          case ActivityType.fuel:
                            context.go('/fuel');
                            break;
                          case ActivityType.service:
                            context.go('/service');
                            break;
                          case ActivityType.expense:
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExpenseDetailScreen(expenseId: item.id),
                              ),
                            );
                            break;
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  Icon(item.icon, color: item.color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dateFormat.format(item.date)} • ${item.subtitle}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${settings.currencySymbol} ${item.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.color,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
