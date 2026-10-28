import '../../fuel/domain/mileage_calculator.dart';
import 'station_insight.dart';

class StationInsightsCalculator {
  /// Computes station analytics and insights from a chronological list of fuel entries.
  static StationInsightsSummary calculate({
    required List<dynamic> entries, // FuelEntryData, chronological ascending
    required Map<String, CalculatedEntryStats> entryStats,
    String economyUnit = 'km/L',
  }) {
    if (entries.isEmpty) {
      return const StationInsightsSummary();
    }

    // Maps: normalizedName -> rawDisplayName
    final Map<String, String> displayNames = {};
    // Maps: normalizedName -> List of entries logged at that station
    final Map<String, List<dynamic>> stationEntries = {};
    // Maps: normalizedName -> List of mileage numbers achieved using fuel from that station
    final Map<String, List<double>> stationMileages = {};

    double totalVehicleFuel = 0.0;
    double totalVehicleSpend = 0.0;
    final List<double> allVehicleMileages = [];

    // Pre-populate overall vehicle stats
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final qty = (e.quantity as num).toDouble();
      final cost = (e.totalCost as num).toDouble();
      totalVehicleFuel += qty;
      totalVehicleSpend += cost;

      final stats = entryStats[e.id as String];
      if (stats?.calculatedMileage != null && stats!.calculatedMileage! > 0) {
        allVehicleMileages.add(stats.calculatedMileage!);

        // Attribute the calculated mileage to the station where that fuel came from.
        // The fuel consumed between entry (i-1) and entry (i) was filled at entry (i-1).
        final sourceEntry = i > 0 ? entries[i - 1] : e;
        final stationRaw = (sourceEntry.stationName as String?)?.trim();
        if (stationRaw != null && stationRaw.isNotEmpty) {
          final key = stationRaw.toLowerCase();
          stationMileages.putIfAbsent(key, () => []).add(stats.calculatedMileage!);
        }
      }

      // Record station entries for price & visit tracking
      final stationRaw = (e.stationName as String?)?.trim();
      if (stationRaw != null && stationRaw.isNotEmpty) {
        final key = stationRaw.toLowerCase();
        displayNames.putIfAbsent(key, () => stationRaw);
        stationEntries.putIfAbsent(key, () => []).add(e);
      }
    }

    final double vehicleAvgPrice = totalVehicleFuel > 0
        ? totalVehicleSpend / totalVehicleFuel
        : 0.0;
    final double vehicleAvgMileage = allVehicleMileages.isNotEmpty
        ? allVehicleMileages.reduce((a, b) => a + b) / allVehicleMileages.length
        : 0.0;

    final List<StationInsight> insights = [];

    for (final entry in stationEntries.entries) {
      final key = entry.key;
      final name = displayNames[key] ?? key;
      final eList = entry.value;

      double stationVolume = 0.0;
      double stationSpend = 0.0;
      double minPrice = double.infinity;
      double maxPrice = 0.0;
      DateTime lastVisited = DateTime.fromMillisecondsSinceEpoch(0);

      for (final e in eList) {
        final qty = (e.quantity as num).toDouble();
        final cost = (e.totalCost as num).toDouble();
        final price = (e.pricePerUnit as num).toDouble();
        final date = e.entryDateTime as DateTime;

        stationVolume += qty;
        stationSpend += cost;

        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
        if (date.isAfter(lastVisited)) lastVisited = date;
      }

      if (minPrice == double.infinity) minPrice = 0.0;

      final double avgPrice = stationVolume > 0
          ? stationSpend / stationVolume
          : 0.0;

      // Average mileage for this station
      double? avgMileage;
      final mileages = stationMileages[key];
      if (mileages != null && mileages.isNotEmpty) {
        avgMileage = mileages.reduce((a, b) => a + b) / mileages.length;
      }

      double? diffVsAvg;
      if (avgMileage != null && vehicleAvgMileage > 0) {
        diffVsAvg = avgMileage - vehicleAvgMileage;
      }

      insights.add(
        StationInsight(
          stationName: name,
          visitCount: eList.length,
          totalVolume: stationVolume,
          totalSpend: stationSpend,
          averagePrice: avgPrice,
          minPrice: minPrice,
          maxPrice: maxPrice,
          averageMileage: avgMileage,
          lastVisited: lastVisited,
          mileageDiffVsAvg: diffVsAvg,
        ),
      );
    }

    if (insights.isEmpty) {
      return StationInsightsSummary(
        vehicleAverageMileage: vehicleAvgMileage,
        vehicleAveragePrice: vehicleAvgPrice,
      );
    }

    // Determine Best Mileage Station
    // Only stations with valid mileage
    final stationsWithMileage =
        insights.where((s) => s.averageMileage != null && s.averageMileage! > 0).toList();

    StationInsight? bestMileage;
    if (stationsWithMileage.isNotEmpty) {
      if (economyUnit == 'L/100km') {
        // Lower L/100km is better
        stationsWithMileage.sort((a, b) => a.averageMileage!.compareTo(b.averageMileage!));
      } else {
        // Higher km/L or MPG is better
        stationsWithMileage.sort((a, b) => b.averageMileage!.compareTo(a.averageMileage!));
      }
      bestMileage = stationsWithMileage.first;
    }

    // Determine Lowest Price Station
    final stationsWithPrice = insights.where((s) => s.averagePrice > 0).toList();
    StationInsight? lowestPrice;
    if (stationsWithPrice.isNotEmpty) {
      stationsWithPrice.sort((a, b) => a.averagePrice.compareTo(b.averagePrice));
      lowestPrice = stationsWithPrice.first;
    }

    // Decorate insights with flags
    final decoratedInsights = insights.map((s) {
      final isBestM = bestMileage != null && s.stationName.toLowerCase() == bestMileage.stationName.toLowerCase();
      final isLowestP = lowestPrice != null && s.stationName.toLowerCase() == lowestPrice.stationName.toLowerCase();

      return StationInsight(
        stationName: s.stationName,
        visitCount: s.visitCount,
        totalVolume: s.totalVolume,
        totalSpend: s.totalSpend,
        averagePrice: s.averagePrice,
        minPrice: s.minPrice,
        maxPrice: s.maxPrice,
        averageMileage: s.averageMileage,
        lastVisited: s.lastVisited,
        isBestMileage: isBestM,
        isLowestPrice: isLowestP,
        mileageDiffVsAvg: s.mileageDiffVsAvg,
      );
    }).toList();

    // Sort by visit count descending
    decoratedInsights.sort((a, b) => b.visitCount.compareTo(a.visitCount));

    return StationInsightsSummary(
      stations: decoratedInsights,
      bestMileageStation: bestMileage,
      lowestPriceStation: lowestPrice,
      vehicleAverageMileage: vehicleAvgMileage,
      vehicleAveragePrice: vehicleAvgPrice,
    );
  }
}
