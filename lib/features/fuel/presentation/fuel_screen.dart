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
import '../data/fuel_entries_repository.dart';
import '../domain/fuel_unit_converter.dart';
import '../domain/mileage_calculator.dart';
import '../../smart/domain/mileage_drop_detector.dart';
import '../../smart/presentation/station_insights_screen.dart';
import '../../smart/presentation/trip_cost_calculator_screen.dart';
import '../../smart/presentation/widgets/mileage_drop_alert_card.dart';
import 'fuel_entry_form_screen.dart';

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  void _openAddEntry(BuildContext context, VehicleData vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FuelEntryFormScreen(vehicle: vehicle),
      ),
    );
  }

  void _openEditEntry(BuildContext context, VehicleData vehicle, FuelEntryData entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FuelEntryFormScreen(vehicle: vehicle, entryToEdit: entry),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FuelEntryData entry,
  ) {
    final repo = ref.read(fuelEntriesRepositoryProvider);
    repo.softDelete(entry.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fill-up (${entry.quantity.toStringAsFixed(1)}L) deleted',
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryAmberLight,
          onPressed: () => repo.restore(entry.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentVehicle = ref.watch(currentVehicleProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: VehicleAppBar(
        title: l10n.navFuel,
        actions: [
          if (currentVehicle != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Log Fill-Up',
              onPressed: () => _openAddEntry(context, currentVehicle),
            ),
        ],
      ),
      floatingActionButton: currentVehicle != null
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEntry(context, currentVehicle),
              backgroundColor: AppColors.primaryAmber,
              icon: const Icon(Icons.local_gas_station_rounded),
              label: Text(l10n.addFuel),
            )
          : null,
      body: currentVehicle == null
          ? _buildNoVehicleState(context, l10n)
          : _buildFuelContent(context, ref, currentVehicle, settings),
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
                color: AppColors.primaryAmber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 64,
                color: AppColors.primaryAmber,
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

  Widget _buildFuelContent(
    BuildContext context,
    WidgetRef ref,
    VehicleData vehicle,
    SettingsState settings,
  ) {
    final repo = ref.watch(fuelEntriesRepositoryProvider);
    final entriesStream = repo.watchFuelEntriesForVehicle(vehicle.id);

    return StreamBuilder<List<FuelEntryData>>(
      stream: entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return _buildFuelListEmptyState(context, vehicle);
        }

        // Calculate full-to-full stats across all entries (ascending)
        final statsMap = MileageCalculator.calculateAllEntriesStats(
          entries: entries,
          economyUnit: vehicle.economyUnit,
        );

        final summary = MileageCalculator.calculateVehicleSummary(
          entries: entries,
          entryStats: statsMap,
          economyUnit: vehicle.economyUnit,
        );

        final latestAnomaly = MileageDropDetector.detectLatestAnomaly(
          entries: entries,
          entryStats: statsMap,
          economyUnit: vehicle.economyUnit,
        );

        // Group entries descending by month for display
        final reversedEntries = entries.reversed.toList();
        final Map<String, List<FuelEntryData>> grouped = {};

        for (final entry in reversedEntries) {
          final monthKey = DateFormat('MMMM yyyy').format(entry.entryDateTime);
          grouped.putIfAbsent(monthKey, () => []).add(entry);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 84),
          children: [
            // Vehicle Summary Banner
            _buildSummaryBanner(context, summary, vehicle, settings),

            // Smart Tools Strip (Station Insights & Trip Calculator)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StationInsightsScreen()),
                        );
                      },
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: const Text('Stations', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TripCostCalculatorScreen()),
                        );
                      },
                      icon: const Icon(Icons.route_rounded, size: 18),
                      label: const Text('Trip Calc', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mileage Drop Alert if detected on latest fill-up
            if (latestAnomaly != null)
              MileageDropAlertCard(alert: latestAnomaly),

            // Grouped Monthly List
            ...grouped.entries.map((group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          group.key,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAmber,
                          ),
                        ),
                        Text(
                          '${group.value.length} fill-ups',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ...group.value.map((entry) {
                    final stats = statsMap[entry.id];
                    return _buildEntryCard(
                      context,
                      ref,
                      vehicle,
                      entry,
                      stats,
                      settings,
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSummaryBanner(
    BuildContext context,
    VehicleFuelSummary summary,
    VehicleData vehicle,
    SettingsState settings,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBannerItem(
                  context,
                  title: 'Avg. Mileage',
                  value: FuelUnitConverter.formatEconomy(
                      summary.avgMileage, vehicle.economyUnit),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primaryAmber,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _buildBannerItem(
                  context,
                  title: 'Best Mileage',
                  value: FuelUnitConverter.formatEconomy(
                      summary.bestMileage, vehicle.economyUnit),
                  icon: Icons.star_rounded,
                  color: AppColors.success,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _buildBannerItem(
                  context,
                  title: 'Worst Mileage',
                  value: FuelUnitConverter.formatEconomy(
                      summary.worstMileage, vehicle.economyUnit),
                  icon: Icons.trending_down_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubStat(
                context,
                label: 'Total Fuel',
                value:
                    '${summary.totalFuel.toStringAsFixed(1)} ${vehicle.volumeUnit}',
              ),
              _buildSubStat(
                context,
                label: 'Total Spent',
                value:
                    '${settings.currencySymbol} ${summary.totalCost.toStringAsFixed(0)}',
              ),
              _buildSubStat(
                context,
                label: 'Avg. Price',
                value:
                    '${settings.currencySymbol} ${summary.avgPricePerUnit.toStringAsFixed(1)} / ${vehicle.volumeUnit}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VehicleData vehicle,
    FuelEntryData entry,
    CalculatedEntryStats? stats,
    SettingsState settings,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry?'),
            content: const Text('Are you sure you want to remove this fuel entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _confirmDelete(context, ref, entry),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEditEntry(context, vehicle, entry),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Station / Date / Mileage Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.stationName ?? 'Fuel Fill-Up',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (entry.receiptPath != null) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.receipt_rounded,
                                  size: 16,
                                  color: AppColors.primaryAmber,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(entry.entryDateTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Mileage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: stats?.calculatedMileage != null
                            ? AppColors.primaryAmber.withValues(alpha: 0.15)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            FuelUnitConverter.formatEconomy(
                                stats?.calculatedMileage, vehicle.economyUnit),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: stats?.calculatedMileage != null
                                  ? AppColors.primaryAmberDark
                                  : null,
                            ),
                          ),
                          if (stats?.costPerKm != null)
                            Text(
                              '${settings.currencySymbol}${stats!.costPerKm!.toStringAsFixed(1)}/${vehicle.distanceUnit}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details Row: Quantity, Price, Total Cost, Odometer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.quantity.toStringAsFixed(2)} ${vehicle.volumeUnit} @ ${settings.currencySymbol}${entry.pricePerUnit.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          entry.fuelType.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                          ),
                        ),
                        Text(
                          '${entry.odometer.toStringAsFixed(0)} ${vehicle.distanceUnit} ${stats?.distanceSinceLast != null ? '(+${stats!.distanceSinceLast!.toStringAsFixed(0)})' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),

                // Tags Row: Partial / Missed
                if (!entry.isFullTank || entry.isMissedPrevious) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (!entry.isFullTank)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Partial Fill',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      if (entry.isMissedPrevious)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Missed Fill-Up',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuelListEmptyState(BuildContext context, VehicleData vehicle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                size: 56,
                color: AppColors.primaryAmber,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No fill-ups logged yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your first fill-up for ${vehicle.name} to track mileage and fuel spend.',
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
              onPressed: () => _openAddEntry(context, vehicle),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log First Fill-Up'),
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
}
