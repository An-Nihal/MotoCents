class TripCalculationInput {
  final double oneWayDistance;
  final bool isRoundTrip;
  final double fuelEconomy;
  final String economyUnit;
  final double fuelPricePerUnit;
  final int passengers;
  final double additionalExpenses;
  final double? tankCapacity;

  const TripCalculationInput({
    required this.oneWayDistance,
    this.isRoundTrip = false,
    required this.fuelEconomy,
    this.economyUnit = 'km/L',
    required this.fuelPricePerUnit,
    this.passengers = 1,
    this.additionalExpenses = 0.0,
    this.tankCapacity,
  });

  TripCalculationInput copyWith({
    double? oneWayDistance,
    bool? isRoundTrip,
    double? fuelEconomy,
    String? economyUnit,
    double? fuelPricePerUnit,
    int? passengers,
    double? additionalExpenses,
    double? tankCapacity,
  }) {
    return TripCalculationInput(
      oneWayDistance: oneWayDistance ?? this.oneWayDistance,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      fuelEconomy: fuelEconomy ?? this.fuelEconomy,
      economyUnit: economyUnit ?? this.economyUnit,
      fuelPricePerUnit: fuelPricePerUnit ?? this.fuelPricePerUnit,
      passengers: passengers ?? this.passengers,
      additionalExpenses: additionalExpenses ?? this.additionalExpenses,
      tankCapacity: tankCapacity ?? this.tankCapacity,
    );
  }
}

class TripCalculationResult {
  final double totalDistance;
  final double fuelNeededVolume;
  final double estimatedFuelCost;
  final double totalTripCost;
  final double costPerPerson;
  final double costPerKm;
  final double? tankPercentageUsed;
  final int fullTanksCount;

  const TripCalculationResult({
    required this.totalDistance,
    required this.fuelNeededVolume,
    required this.estimatedFuelCost,
    required this.totalTripCost,
    required this.costPerPerson,
    required this.costPerKm,
    this.tankPercentageUsed,
    required this.fullTanksCount,
  });
}
