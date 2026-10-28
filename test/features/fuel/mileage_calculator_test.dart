import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_and_service_log/features/fuel/domain/fuel_unit_converter.dart';
import 'package:fuel_and_service_log/features/fuel/domain/mileage_calculator.dart';

class MockFuelEntry {
  final String id;
  final double odometer;
  final double quantity;
  final double totalCost;
  final bool isFullTank;
  final bool isMissedPrevious;

  MockFuelEntry({
    required this.id,
    required this.odometer,
    required this.quantity,
    required this.totalCost,
    this.isFullTank = true,
    this.isMissedPrevious = false,
  });
}

void main() {
  group('MileageCalculator - Full to Full logic', () {
    test('First entry cannot calculate mileage (no previous full tank)', () {
      final entries = [
        MockFuelEntry(
          id: '1',
          odometer: 10000.0,
          quantity: 40.0,
          totalCost: 5200.0,
          isFullTank: true,
        ),
      ];

      final stats = MileageCalculator.calculateAllEntriesStats(entries: entries);
      expect(stats['1']?.calculatedMileage, isNull);
      expect(stats['1']?.distanceSinceLast, isNull);
    });

    test('Two consecutive full tanks calculate mileage correctly', () {
      final entries = [
        MockFuelEntry(
          id: '1',
          odometer: 10000.0,
          quantity: 40.0,
          totalCost: 5200.0,
          isFullTank: true,
        ),
        MockFuelEntry(
          id: '2',
          odometer: 10500.0, // 500 km
          quantity: 35.0, // 35 L
          totalCost: 4550.0,
          isFullTank: true,
        ),
      ];

      final stats = MileageCalculator.calculateAllEntriesStats(entries: entries);
      expect(stats['1']?.calculatedMileage, isNull);
      expect(stats['2']?.distanceSinceLast, 500.0);
      // Mileage = 500 / 35 = ~14.2857 km/L
      expect(stats['2']?.calculatedMileage, closeTo(14.285, 0.01));
      // Cost per km = 4550 / 500 = 9.1
      expect(stats['2']?.costPerKm, closeTo(9.1, 0.01));
    });

    test('Partial fill-ups sum fuel used until next full tank', () {
      final entries = [
        // Entry 1: Full tank at 10000
        MockFuelEntry(
          id: '1',
          odometer: 10000.0,
          quantity: 40.0,
          totalCost: 5200.0,
          isFullTank: true,
        ),
        // Entry 2: Partial fill-up (10L) at 10200
        MockFuelEntry(
          id: '2',
          odometer: 10200.0,
          quantity: 10.0,
          totalCost: 1300.0,
          isFullTank: false,
        ),
        // Entry 3: Another partial (15L) at 10450
        MockFuelEntry(
          id: '3',
          odometer: 10450.0,
          quantity: 15.0,
          totalCost: 1950.0,
          isFullTank: false,
        ),
        // Entry 4: Full tank (25L) at 10800
        MockFuelEntry(
          id: '4',
          odometer: 10800.0,
          quantity: 25.0,
          totalCost: 3250.0,
          isFullTank: true,
        ),
      ];

      final stats = MileageCalculator.calculateAllEntriesStats(entries: entries);

      // Partials should not show full-to-full mileage
      expect(stats['2']?.calculatedMileage, isNull);
      expect(stats['3']?.calculatedMileage, isNull);
      expect(stats['2']?.distanceSinceLast, 200.0);
      expect(stats['3']?.distanceSinceLast, 250.0);

      // Entry 4 is Full:
      // Distance = 10800 - 10000 = 800 km
      // Fuel used = 10 + 15 + 25 = 50 L
      // Mileage = 800 / 50 = 16.0 km/L
      expect(stats['4']?.calculatedMileage, closeTo(16.0, 0.01));
      expect(stats['4']?.distanceSinceLast, 350.0); // 10800 - 10450
    });

    test('Missed previous fill-up suppresses mileage calculation', () {
      final entries = [
        MockFuelEntry(
          id: '1',
          odometer: 10000.0,
          quantity: 40.0,
          totalCost: 5200.0,
          isFullTank: true,
        ),
        // Entry 2: Full tank, but user missed recording an intermediate fill-up
        MockFuelEntry(
          id: '2',
          odometer: 10900.0,
          quantity: 35.0,
          totalCost: 4550.0,
          isFullTank: true,
          isMissedPrevious: true,
        ),
        // Entry 3: Next regular full tank
        MockFuelEntry(
          id: '3',
          odometer: 11400.0, // 500 km
          quantity: 35.0, // 35 L
          totalCost: 4550.0,
          isFullTank: true,
        ),
      ];

      final stats = MileageCalculator.calculateAllEntriesStats(entries: entries);

      // Entry 2 has missedPrevious -> mileage is null
      expect(stats['2']?.calculatedMileage, isNull);

      // Entry 3 can calculate using Entry 2 as the baseline!
      // Distance = 11400 - 10900 = 500 km
      // Fuel used = 35 L
      // Mileage = 500 / 35 = ~14.28 km/L
      expect(stats['3']?.calculatedMileage, closeTo(14.285, 0.01));
    });

    test('Economy unit conversion converts correctly to L/100km and MPG', () {
      final entries = [
        MockFuelEntry(
          id: '1',
          odometer: 1000.0,
          quantity: 40.0,
          totalCost: 4000.0,
          isFullTank: true,
        ),
        MockFuelEntry(
          id: '2',
          odometer: 1500.0, // 500 km / 25 L = 20.0 km/L
          quantity: 25.0,
          totalCost: 2500.0,
          isFullTank: true,
        ),
      ];

      final statsKmL = MileageCalculator.calculateAllEntriesStats(
        entries: entries,
        economyUnit: 'km/L',
      );
      expect(statsKmL['2']?.calculatedMileage, 20.0);

      // In L/100km: 100 / 20 = 5.0 L/100km
      final statsL100 = MileageCalculator.calculateAllEntriesStats(
        entries: entries,
        economyUnit: 'L/100km',
      );
      expect(statsL100['2']?.calculatedMileage, 5.0);

      // In US MPG: 20 * 2.35214583 = ~47.04 MPG
      final statsMpg = MileageCalculator.calculateAllEntriesStats(
        entries: entries,
        economyUnit: 'MPG',
      );
      expect(statsMpg['2']?.calculatedMileage, closeTo(47.04, 0.05));
    });

    test('Vehicle summary statistics computes best, worst, avg, and totals', () {
      final entries = [
        MockFuelEntry(
          id: '1',
          odometer: 1000.0,
          quantity: 20.0,
          totalCost: 2600.0,
          isFullTank: true,
        ),
        MockFuelEntry(
          id: '2',
          odometer: 1300.0, // 300 / 20 = 15.0 km/L
          quantity: 20.0,
          totalCost: 2600.0,
          isFullTank: true,
        ),
        MockFuelEntry(
          id: '3',
          odometer: 1700.0, // 400 / 20 = 20.0 km/L
          quantity: 20.0,
          totalCost: 2600.0,
          isFullTank: true,
        ),
      ];

      final entryStats = MileageCalculator.calculateAllEntriesStats(entries: entries);
      final summary = MileageCalculator.calculateVehicleSummary(
        entries: entries,
        entryStats: entryStats,
      );

      expect(summary.totalFuel, 60.0);
      expect(summary.totalCost, 7800.0);
      expect(summary.avgPricePerUnit, 130.0);
      expect(summary.bestMileage, 20.0);
      expect(summary.worstMileage, 15.0);
      expect(summary.avgMileage, 17.5);
      expect(summary.totalFillUps, 3);
    });
  });

  group('FuelUnitConverter', () {
    test('Distance conversions', () {
      expect(FuelUnitConverter.convertDistance(100, from: 'km', to: 'mi'), closeTo(62.137, 0.01));
      expect(FuelUnitConverter.convertDistance(62.1371, from: 'mi', to: 'km'), closeTo(100.0, 0.01));
      expect(FuelUnitConverter.convertDistance(50, from: 'km', to: 'km'), 50.0);
    });

    test('Volume conversions', () {
      expect(FuelUnitConverter.convertVolume(10, from: 'L', to: 'gal'), closeTo(2.6417, 0.01));
      expect(FuelUnitConverter.convertVolume(2.64172, from: 'gal', to: 'L'), closeTo(10.0, 0.01));
    });

    test('Format economy handles null and infinity gracefully', () {
      expect(FuelUnitConverter.formatEconomy(null, 'km/L'), '—');
      expect(FuelUnitConverter.formatEconomy(double.infinity, 'km/L'), '—');
      expect(FuelUnitConverter.formatEconomy(15.42, 'km/L'), '15.4 km/L');
    });
  });
}
