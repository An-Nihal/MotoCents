import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/features/smart/domain/trip_calculator_models.dart';
import 'package:fuel_and_service_log/features/smart/domain/trip_cost_calculator.dart';

void main() {
  group('TripCostCalculator Unit Tests', () {
    test('Calculates one-way trip fuel and cost accurately (km/L)', () {
      const input = TripCalculationInput(
        oneWayDistance: 150.0,
        isRoundTrip: false,
        fuelEconomy: 15.0, // 15 km/L
        economyUnit: 'km/L',
        fuelPricePerUnit: 130.0,
        passengers: 1,
      );

      final result = TripCostCalculator.calculate(input);

      expect(result.totalDistance, 150.0);
      expect(result.fuelNeededVolume, 10.0); // 150 / 15
      expect(result.estimatedFuelCost, 1300.0); // 10 * 130
      expect(result.totalTripCost, 1300.0);
      expect(result.costPerPerson, 1300.0);
      expect(result.costPerKm, closeTo(8.67, 0.01));
    });

    test('Doubles distance and fuel for round-trip travel', () {
      const input = TripCalculationInput(
        oneWayDistance: 150.0,
        isRoundTrip: true, // 300 km total
        fuelEconomy: 15.0,
        economyUnit: 'km/L',
        fuelPricePerUnit: 130.0,
      );

      final result = TripCostCalculator.calculate(input);

      expect(result.totalDistance, 300.0);
      expect(result.fuelNeededVolume, 20.0); // 300 / 15
      expect(result.estimatedFuelCost, 2600.0); // 20 * 130
      expect(result.totalTripCost, 2600.0);
    });

    test('Correctly calculates fuel needed for L/100km economy unit', () {
      const input = TripCalculationInput(
        oneWayDistance: 250.0,
        isRoundTrip: false,
        fuelEconomy: 8.0, // 8.0 L / 100km
        economyUnit: 'L/100km',
        fuelPricePerUnit: 125.0,
      );

      final result = TripCostCalculator.calculate(input);

      // (250 / 100) * 8 = 20 L
      expect(result.fuelNeededVolume, 20.0);
      expect(result.estimatedFuelCost, 2500.0); // 20 * 125
    });

    test('Splits total cost evenly across passengers and includes tolls', () {
      const input = TripCalculationInput(
        oneWayDistance: 200.0,
        isRoundTrip: false,
        fuelEconomy: 10.0, // 20 L fuel
        economyUnit: 'km/L',
        fuelPricePerUnit: 100.0, // 2000.0 fuel cost
        passengers: 4,
        additionalExpenses: 400.0, // tolls & parking
      );

      final result = TripCostCalculator.calculate(input);

      expect(result.estimatedFuelCost, 2000.0);
      expect(result.totalTripCost, 2400.0); // 2000 + 400
      expect(result.costPerPerson, 600.0); // 2400 / 4
    });

    test('Computes vehicle tank percentage and full tanks required', () {
      const input = TripCalculationInput(
        oneWayDistance: 600.0,
        isRoundTrip: false,
        fuelEconomy: 10.0, // 60 L needed
        economyUnit: 'km/L',
        fuelPricePerUnit: 130.0,
        tankCapacity: 40.0, // 40 L tank
      );

      final result = TripCostCalculator.calculate(input);

      expect(result.fuelNeededVolume, 60.0);
      expect(result.tankPercentageUsed, 150.0); // 60 / 40 = 150%
      expect(result.fullTanksCount, 2); // ceil(60 / 40) = 2 tanks
    });

    test('Safely handles zero distance and zero economy edge cases', () {
      const input = TripCalculationInput(
        oneWayDistance: 0.0,
        fuelEconomy: 0.0,
        fuelPricePerUnit: 130.0,
      );

      final result = TripCostCalculator.calculate(input);

      expect(result.totalDistance, 0.0);
      expect(result.fuelNeededVolume, 0.0);
      expect(result.estimatedFuelCost, 0.0);
      expect(result.totalTripCost, 0.0);
    });
  });
}
