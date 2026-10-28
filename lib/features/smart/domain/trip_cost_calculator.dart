import 'trip_calculator_models.dart';

class TripCostCalculator {
  /// Calculates fuel needed, fuel cost, total trip cost, and cost per passenger.
  static TripCalculationResult calculate(TripCalculationInput input) {
    final effectiveDistance = input.isRoundTrip
        ? input.oneWayDistance * 2.0
        : input.oneWayDistance;

    if (effectiveDistance <= 0 || input.fuelEconomy <= 0) {
      return TripCalculationResult(
        totalDistance: effectiveDistance > 0 ? effectiveDistance : 0.0,
        fuelNeededVolume: 0.0,
        estimatedFuelCost: 0.0,
        totalTripCost: input.additionalExpenses > 0 ? input.additionalExpenses : 0.0,
        costPerPerson: input.additionalExpenses > 0
            ? input.additionalExpenses / (input.passengers > 0 ? input.passengers : 1)
            : 0.0,
        costPerKm: 0.0,
        tankPercentageUsed: 0.0,
        fullTanksCount: 0,
      );
    }

    // Calculate fuel volume based on economy unit
    double fuelNeeded;
    if (input.economyUnit == 'L/100km') {
      fuelNeeded = (effectiveDistance / 100.0) * input.fuelEconomy;
    } else {
      // km/L or MPG
      fuelNeeded = effectiveDistance / input.fuelEconomy;
    }

    final double fuelCost = fuelNeeded * input.fuelPricePerUnit;
    final double totalCost = fuelCost + input.additionalExpenses;
    final int safePassengers = input.passengers >= 1 ? input.passengers : 1;
    final double costPerPerson = totalCost / safePassengers;
    final double costPerKm = effectiveDistance > 0 ? totalCost / effectiveDistance : 0.0;

    double? tankPercentageUsed;
    int fullTanksCount = 0;

    if (input.tankCapacity != null && input.tankCapacity! > 0) {
      tankPercentageUsed = (fuelNeeded / input.tankCapacity!) * 100.0;
      fullTanksCount = (fuelNeeded / input.tankCapacity!).ceil();
    }

    return TripCalculationResult(
      totalDistance: effectiveDistance,
      fuelNeededVolume: fuelNeeded,
      estimatedFuelCost: fuelCost,
      totalTripCost: totalCost,
      costPerPerson: costPerPerson,
      costPerKm: costPerKm,
      tankPercentageUsed: tankPercentageUsed,
      fullTanksCount: fullTanksCount,
    );
  }
}
