import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/vehicles_provider.dart';
import '../../../fuel/domain/mileage_calculator.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../domain/mileage_anomaly.dart';
import '../../domain/mileage_drop_detector.dart';
import '../../domain/station_insight.dart';
import '../../domain/station_insights_calculator.dart';

/// Provider for Station Insights Analytics
final stationInsightsSummaryProvider =
    Provider.autoDispose<AsyncValue<StationInsightsSummary>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  if (vehicle == null) {
    return const AsyncValue.data(StationInsightsSummary());
  }

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  return fuelAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
    data: (entries) {
      final sorted = List.of(entries)
        ..sort((a, b) => a.entryDateTime.compareTo(b.entryDateTime));

      final stats = MileageCalculator.calculateAllEntriesStats(
        entries: sorted,
        economyUnit: vehicle.economyUnit,
      );

      final summary = StationInsightsCalculator.calculate(
        entries: sorted,
        entryStats: stats,
        economyUnit: vehicle.economyUnit,
      );

      return AsyncValue.data(summary);
    },
  );
});

/// Provider detecting if the most recent fill-up suffered a > 15% mileage drop anomaly
final latestMileageAnomalyProvider =
    Provider.autoDispose<AsyncValue<MileageDropAlert?>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  if (vehicle == null) {
    return const AsyncValue.data(null);
  }

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  return fuelAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
    data: (entries) {
      final sorted = List.of(entries)
        ..sort((a, b) => a.entryDateTime.compareTo(b.entryDateTime));

      final stats = MileageCalculator.calculateAllEntriesStats(
        entries: sorted,
        economyUnit: vehicle.economyUnit,
      );

      final alert = MileageDropDetector.detectLatestAnomaly(
        entries: sorted,
        entryStats: stats,
        economyUnit: vehicle.economyUnit,
      );

      return AsyncValue.data(alert);
    },
  );
});

/// Default baseline values for the Trip Cost Calculator (average mileage & latest price)
class VehicleTripDefaults {
  final double defaultEconomy;
  final double defaultPrice;
  final String economyUnit;
  final String distanceUnit;
  final String volumeUnit;
  final double? tankCapacity;

  const VehicleTripDefaults({
    required this.defaultEconomy,
    required this.defaultPrice,
    required this.economyUnit,
    required this.distanceUnit,
    required this.volumeUnit,
    this.tankCapacity,
  });
}

final vehicleTripDefaultsProvider =
    Provider.autoDispose<AsyncValue<VehicleTripDefaults>>((ref) {
  final vehicle = ref.watch(currentVehicleProvider);
  if (vehicle == null) {
    return const AsyncValue.data(
      VehicleTripDefaults(
        defaultEconomy: 12.0,
        defaultPrice: 130.0,
        economyUnit: 'km/L',
        distanceUnit: 'km',
        volumeUnit: 'L',
      ),
    );
  }

  final fuelAsync = ref.watch(vehicleFuelEntriesStreamProvider(vehicle.id));
  return fuelAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
    data: (entries) {
      final sorted = List.of(entries)
        ..sort((a, b) => a.entryDateTime.compareTo(b.entryDateTime));

      final stats = MileageCalculator.calculateAllEntriesStats(
        entries: sorted,
        economyUnit: vehicle.economyUnit,
      );

      final summary = MileageCalculator.calculateVehicleSummary(
        entries: sorted,
        entryStats: stats,
        economyUnit: vehicle.economyUnit,
      );

      final latestPrice = sorted.isNotEmpty
          ? sorted.last.pricePerUnit
          : 130.0;
      final defaultEconomy = (summary.avgMileage != null && summary.avgMileage! > 0)
          ? summary.avgMileage!
          : (vehicle.economyUnit == 'L/100km' ? 8.0 : 12.0);

      return AsyncValue.data(
        VehicleTripDefaults(
          defaultEconomy: defaultEconomy,
          defaultPrice: latestPrice,
          economyUnit: vehicle.economyUnit,
          distanceUnit: vehicle.distanceUnit,
          volumeUnit: vehicle.volumeUnit,
          tankCapacity: vehicle.tankCapacity,
        ),
      );
    },
  );
});
