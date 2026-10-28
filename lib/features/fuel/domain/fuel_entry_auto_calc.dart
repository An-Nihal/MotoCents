enum AutoCalcTarget { quantity, pricePerUnit, totalCost }

class FuelEntryAutoCalc {
  /// Calculate third value given any two of quantity, pricePerUnit, and totalCost.
  /// If price and total are provided -> computes quantity.
  /// If quantity and price are provided -> computes total.
  /// If quantity and total are provided -> computes price.
  static double? calculateThird({
    double? quantity,
    double? pricePerUnit,
    double? totalCost,
    required AutoCalcTarget target,
  }) {
    switch (target) {
      case AutoCalcTarget.quantity:
        if (totalCost != null && pricePerUnit != null && pricePerUnit > 0) {
          return double.parse((totalCost / pricePerUnit).toStringAsFixed(3));
        }
        return null;

      case AutoCalcTarget.pricePerUnit:
        if (totalCost != null && quantity != null && quantity > 0) {
          return double.parse((totalCost / quantity).toStringAsFixed(2));
        }
        return null;

      case AutoCalcTarget.totalCost:
        if (quantity != null && pricePerUnit != null && quantity > 0 && pricePerUnit > 0) {
          return double.parse((quantity * pricePerUnit).toStringAsFixed(2));
        }
        return null;
    }
  }

  /// Convert trip meter distance to total odometer reading given previous entry odometer.
  static double convertTripToOdometer({
    required double tripDistance,
    required double previousOdometer,
  }) {
    return previousOdometer + tripDistance;
  }

  /// Validates odometer against previous odometer.
  /// Returns null if valid, or an error/warning message.
  static String? validateOdometer({
    required double newOdometer,
    double? previousOdometer,
  }) {
    if (newOdometer <= 0) {
      return 'Odometer reading must be greater than 0';
    }
    if (previousOdometer != null && newOdometer <= previousOdometer) {
      return 'Odometer must be greater than previous (${previousOdometer.toStringAsFixed(0)})';
    }
    return null;
  }

  /// Checks if the jump in odometer is unusually large (e.g. > 2,000 km in a single fill-up).
  static bool isUnusuallyLargeJump({
    required double newOdometer,
    double? previousOdometer,
    double threshold = 2000.0,
  }) {
    if (previousOdometer == null) return false;
    final diff = newOdometer - previousOdometer;
    return diff > threshold;
  }
}
