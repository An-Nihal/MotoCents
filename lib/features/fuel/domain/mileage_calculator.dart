import 'fuel_unit_converter.dart';

class CalculatedEntryStats {
  final String entryId;
  final double? calculatedMileage; // in vehicle's economyUnit
  final double? distanceSinceLast; // in vehicle's distanceUnit
  final double? costPerKm; // in currency/distanceUnit

  const CalculatedEntryStats({
    required this.entryId,
    this.calculatedMileage,
    this.distanceSinceLast,
    this.costPerKm,
  });
}

class VehicleFuelSummary {
  final double totalFuel;
  final double totalCost;
  final double avgPricePerUnit;
  final double? avgMileage;
  final double? bestMileage;
  final double? worstMileage;
  final int totalFillUps;

  const VehicleFuelSummary({
    required this.totalFuel,
    required this.totalCost,
    required this.avgPricePerUnit,
    this.avgMileage,
    this.bestMileage,
    this.worstMileage,
    required this.totalFillUps,
  });

  factory VehicleFuelSummary.empty() {
    return const VehicleFuelSummary(
      totalFuel: 0.0,
      totalCost: 0.0,
      avgPricePerUnit: 0.0,
      avgMileage: null,
      bestMileage: null,
      worstMileage: null,
      totalFillUps: 0,
    );
  }
}

class MileageCalculator {
  /// Calculates mileage and stats for a chronological list of fuel fill-ups.
  /// Entries MUST be sorted by date/odometer ascending.
  static Map<String, CalculatedEntryStats> calculateAllEntriesStats({
    required List<dynamic> entries, // FuelEntryData or map-like objects
    String economyUnit = 'km/L',
  }) {
    final Map<String, CalculatedEntryStats> results = {};

    for (int i = 0; i < entries.length; i++) {
      final current = entries[i];
      final currentOdo = (current.odometer as num).toDouble();
      final currentCost = (current.totalCost as num).toDouble();

      // Distance since immediate previous entry
      double? distanceSinceLast;
      double? costPerKm;

      if (i > 0) {
        final prev = entries[i - 1];
        final prevOdo = (prev.odometer as num).toDouble();
        final diff = currentOdo - prevOdo;
        if (diff > 0) {
          distanceSinceLast = diff;
          costPerKm = currentCost / diff;
        }
      }

      // Full-to-full mileage calculation
      double? mileage;
      final bool isFull = current.isFullTank as bool;

      if (isFull) {
        // Find previous full-tank entry j
        int prevFullIndex = -1;
        for (int j = i - 1; j >= 0; j--) {
          if (entries[j].isFullTank as bool) {
            prevFullIndex = j;
            break;
          }
        }

        if (prevFullIndex != -1) {
          final prevFull = entries[prevFullIndex];
          final prevFullOdo = (prevFull.odometer as num).toDouble();
          final distance = currentOdo - prevFullOdo;

          // Check if any entry in range (prevFullIndex, i] has isMissedPrevious == true
          bool hasMissed = false;
          double fuelUsed = 0.0;

          for (int k = prevFullIndex + 1; k <= i; k++) {
            final entryInRange = entries[k];
            if (entryInRange.isMissedPrevious as bool) {
              hasMissed = true;
              break;
            }
            fuelUsed += (entryInRange.quantity as num).toDouble();
          }

          if (!hasMissed && distance > 0 && fuelUsed > 0) {
            final rawKmL = distance / fuelUsed;
            mileage = FuelUnitConverter.convertEconomy(rawKmL, economyUnit);
          }
        }
      }

      results[current.id as String] = CalculatedEntryStats(
        entryId: current.id as String,
        calculatedMileage: mileage,
        distanceSinceLast: distanceSinceLast,
        costPerKm: costPerKm,
      );
    }

    return results;
  }

  /// Calculates aggregated vehicle fuel stats summary.
  static VehicleFuelSummary calculateVehicleSummary({
    required List<dynamic> entries,
    required Map<String, CalculatedEntryStats> entryStats,
    String economyUnit = 'km/L',
  }) {
    if (entries.isEmpty) {
      return VehicleFuelSummary.empty();
    }

    double totalFuel = 0.0;
    double totalCost = 0.0;
    final List<double> validMileages = [];

    for (final e in entries) {
      totalFuel += (e.quantity as num).toDouble();
      totalCost += (e.totalCost as num).toDouble();

      final stats = entryStats[e.id as String];
      if (stats?.calculatedMileage != null && stats!.calculatedMileage! > 0) {
        validMileages.add(stats.calculatedMileage!);
      }
    }

    final double avgPrice = totalFuel > 0 ? totalCost / totalFuel : 0.0;

    double? avgMileage;
    double? bestMileage;
    double? worstMileage;

    if (validMileages.isNotEmpty) {
      final sum = validMileages.reduce((a, b) => a + b);
      avgMileage = sum / validMileages.length;

      // Note: for L/100km, lower is better, but in km/L and MPG higher is better.
      if (economyUnit == 'L/100km') {
        bestMileage = validMileages.reduce((a, b) => a < b ? a : b); // lowest L/100km is best
        worstMileage = validMileages.reduce((a, b) => a > b ? a : b);
      } else {
        bestMileage = validMileages.reduce((a, b) => a > b ? a : b); // highest is best
        worstMileage = validMileages.reduce((a, b) => a < b ? a : b);
      }
    }

    return VehicleFuelSummary(
      totalFuel: totalFuel,
      totalCost: totalCost,
      avgPricePerUnit: avgPrice,
      avgMileage: avgMileage,
      bestMileage: bestMileage,
      worstMileage: worstMileage,
      totalFillUps: entries.length,
    );
  }
}
