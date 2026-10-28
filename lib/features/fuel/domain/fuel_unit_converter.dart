class FuelUnitConverter {
  // Conversion constants
  static const double kmPerMile = 1.609344;
  static const double litresPerUsGallon = 3.785411784;
  static const double kmLToUsMpgFactor = 2.3521458322792;

  /// Convert distance based on source and target units ('km' or 'mi')
  static double convertDistance(double distance, {required String from, required String to}) {
    if (from == to) return distance;
    if (from == 'km' && to == 'mi') {
      return distance / kmPerMile;
    } else if (from == 'mi' && to == 'km') {
      return distance * kmPerMile;
    }
    return distance;
  }

  /// Convert fuel volume based on source and target units ('L' or 'gal')
  static double convertVolume(double volume, {required String from, required String to}) {
    if (from == to) return volume;
    if (from == 'L' && to == 'gal') {
      return volume / litresPerUsGallon;
    } else if (from == 'gal' && to == 'L') {
      return volume * litresPerUsGallon;
    }
    return volume;
  }

  /// Convert base economy (km/L) to target unit ('km/L', 'L/100km', 'MPG')
  static double? convertEconomy(double kmPerLitre, String targetUnit) {
    if (kmPerLitre <= 0) return null;
    switch (targetUnit) {
      case 'km/L':
        return kmPerLitre;
      case 'L/100km':
        return 100.0 / kmPerLitre;
      case 'MPG':
        return kmPerLitre * kmLToUsMpgFactor;
      default:
        return kmPerLitre;
    }
  }

  /// Format economy value with appropriate unit label
  static String formatEconomy(double? value, String unit, {int decimals = 1}) {
    if (value == null || value.isNaN || value.isInfinite) return '—';
    return '${value.toStringAsFixed(decimals)} $unit';
  }
}
