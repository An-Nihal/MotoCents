import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/vehicles_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../shell/presentation/vehicle_selector_app_bar.dart';
import '../domain/station_insight.dart';
import 'providers/smart_providers.dart';

class StationInsightsScreen extends ConsumerWidget {
  const StationInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    final settings = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(stationInsightsSummaryProvider);

    return Scaffold(
      appBar: const VehicleAppBar(
        title: 'Station Insights',
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading station insights: $err')),
        data: (summary) {
          if (summary.isEmpty) {
            return _buildEmptyState(context);
          }

          final currency = settings.currencySymbol;
          final volumeUnit = vehicle?.volumeUnit ?? 'L';
          final economyUnit = vehicle?.economyUnit ?? 'km/L';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Hero Highlights: Best Efficiency & Lowest Price
              if (summary.bestMileageStation != null || summary.lowestPriceStation != null)
                Row(
                  children: [
                    if (summary.bestMileageStation != null)
                      Expanded(
                        child: _buildHeroCard(
                          context,
                          title: 'Best Mileage',
                          stationName: summary.bestMileageStation!.stationName,
                          metric:
                              '${summary.bestMileageStation!.averageMileage!.toStringAsFixed(1)} $economyUnit',
                          badge: summary.bestMileageStation!.formattedDiff.isNotEmpty
                              ? '${summary.bestMileageStation!.formattedDiff} $economyUnit vs avg'
                              : null,
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    if (summary.bestMileageStation != null && summary.lowestPriceStation != null)
                      const SizedBox(width: 12),
                    if (summary.lowestPriceStation != null)
                      Expanded(
                        child: _buildHeroCard(
                          context,
                          title: 'Lowest Price',
                          stationName: summary.lowestPriceStation!.stationName,
                          metric:
                              '$currency${summary.lowestPriceStation!.averagePrice.toStringAsFixed(1)}/$volumeUnit',
                          badge: 'Min: $currency${summary.lowestPriceStation!.minPrice.toStringAsFixed(1)}',
                          icon: Icons.savings_rounded,
                          color: AppColors.primaryAmber,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),

              // Benchmark bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vehicle Baseline Average:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${summary.vehicleAverageMileage > 0 ? summary.vehicleAverageMileage.toStringAsFixed(1) : '—'} $economyUnit • $currency${summary.vehicleAveragePrice.toStringAsFixed(1)}/$volumeUnit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryAmber,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section header
              Text(
                'Fuel Stations (${summary.stations.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Stations list
              ...summary.stations.map((s) => _buildStationCard(context, s, currency, volumeUnit, economyUnit)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String title,
    required String stationName,
    required String metric,
    String? badge,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            metric,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStationCard(
    BuildContext context,
    StationInsight s,
    String currency,
    String volumeUnit,
    String economyUnit,
  ) {
    final theme = Theme.of(context);
    final hasMileage = s.averageMileage != null && s.averageMileage! > 0;

    Color mileageBadgeColor = Colors.grey;
    if (hasMileage) {
      if (s.mileageDiffVsAvg != null && s.mileageDiffVsAvg! >= 0) {
        mileageBadgeColor = Colors.green;
      } else if (s.mileageDiffVsAvg != null && s.mileageDiffVsAvg! < -0.5) {
        mileageBadgeColor = Colors.orange;
      } else {
        mileageBadgeColor = Colors.blueGrey;
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.stationName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (s.isBestMileage)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🏆 Best Mileage',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryTeal,
                      ),
                    ),
                  )
                else if (s.isLowestPrice)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '💰 Lowest Price',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${s.visitCount} ${s.visitCount == 1 ? 'fill-up' : 'fill-ups'} • Last visited: ${s.lastVisited.day}/${s.lastVisited.month}/${s.lastVisited.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currency${s.averagePrice.toStringAsFixed(2)} / $volumeUnit',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (s.minPrice != s.maxPrice)
                      Text(
                        'Range: $currency${s.minPrice.toStringAsFixed(0)} - $currency${s.maxPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),

                // Mileage Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Average Mileage',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasMileage)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${s.averageMileage!.toStringAsFixed(1)} $economyUnit',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: mileageBadgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.formattedDiff,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: mileageBadgeColor,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No full fill-up data',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Volume: ${s.totalVolume.toStringAsFixed(1)} $volumeUnit',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  'Total Spend: $currency${s.totalSpend.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.15),
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
              'No Station Insights Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill-up logs with station names will automatically calculate fuel quality, mileage differences, and price trends across your favorite stations.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
