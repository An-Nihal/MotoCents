import 'mileage_anomaly.dart';

class MileageDropDetector {
  static const double defaultThresholdPercent = 15.0;

  /// Evaluates whether a given entry has a mileage drop anomaly compared to previous entries.
  static MileageDropAlert? checkEntryForAnomaly({
    required String entryId,
    required double currentMileage,
    required List<double> previousMileages,
    required DateTime entryDate,
    String economyUnit = 'km/L',
    double thresholdPercent = defaultThresholdPercent,
  }) {
    if (previousMileages.isEmpty || currentMileage <= 0) {
      return null;
    }

    // Filter positive values
    final validPrev = previousMileages.where((m) => m > 0).toList();
    if (validPrev.isEmpty) {
      return null;
    }

    // Calculate baseline (rolling average of previous valid fill-ups, max last 5)
    final recentPrev = validPrev.length > 5
        ? validPrev.sublist(validPrev.length - 5)
        : validPrev;

    final baseline = recentPrev.reduce((a, b) => a + b) / recentPrev.length;
    if (baseline <= 0) return null;

    // Drop calculation:
    // In km/L and MPG, higher is better, so drop = (baseline - current) / baseline.
    // In L/100km, lower is better, so drop = (current - baseline) / baseline.
    double dropPercent;
    if (economyUnit == 'L/100km') {
      dropPercent = ((currentMileage - baseline) / baseline) * 100.0;
    } else {
      dropPercent = ((baseline - currentMileage) / baseline) * 100.0;
    }

    if (dropPercent >= thresholdPercent) {
      final severity = dropPercent >= 25.0
          ? AnomalySeverity.critical
          : AnomalySeverity.warning;

      final tips = [
        'Check tyre pressure: Under-inflated tyres can reduce fuel economy by up to 5-10%.',
        'Inspect air filter: A dirty or clogged filter restricts airflow and causes rich combustion.',
        'Evaluate fuel quality: If you recently visited a new filling station, fuel quality or adulteration may be the cause.',
        'Check spark plugs & ignition: Worn spark plugs cause incomplete fuel combustion.',
        'Review driving conditions: Heavy traffic, prolonged AC idling, or aggressive acceleration.',
      ];

      return MileageDropAlert(
        entryId: entryId,
        currentMileage: currentMileage,
        baselineMileage: baseline,
        dropPercentage: dropPercent,
        severity: severity,
        primaryTip: 'Check tyre pressure, air filter, or fuel quality',
        actionableTips: tips,
        entryDate: entryDate,
        economyUnit: economyUnit,
      );
    }

    return null;
  }

  /// Analyzes a chronological list of entries and their computed mileage stats,
  /// returning any detected anomaly on the latest entry.
  static MileageDropAlert? detectLatestAnomaly({
    required List<dynamic> entries, // chronological ascending
    required Map<String, dynamic> entryStats, // map from entryId -> stats with calculatedMileage
    String economyUnit = 'km/L',
    double thresholdPercent = defaultThresholdPercent,
  }) {
    if (entries.isEmpty) return null;

    final List<double> history = [];
    MileageDropAlert? latestAlert;

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final stats = entryStats[e.id];
      final double? mileage = stats?.calculatedMileage as double?;

      if (mileage != null && mileage > 0) {
        if (history.isNotEmpty) {
          final alert = checkEntryForAnomaly(
            entryId: e.id as String,
            currentMileage: mileage,
            previousMileages: history,
            entryDate: e.entryDateTime as DateTime,
            economyUnit: economyUnit,
            thresholdPercent: thresholdPercent,
          );
          if (alert != null && i == entries.length - 1) {
            latestAlert = alert;
          }
        }
        history.add(mileage);
      }
    }

    return latestAlert;
  }
}
