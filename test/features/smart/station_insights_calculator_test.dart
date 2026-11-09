import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/fuel/domain/mileage_calculator.dart';
import 'package:motocents/features/smart/domain/station_insights_calculator.dart';

class MockFuelEntry {
  final String id;
  final DateTime entryDateTime;
  final double quantity;
  final double pricePerUnit;
  final double totalCost;
  final String? stationName;

  MockFuelEntry({
    required this.id,
    required this.entryDateTime,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalCost,
    this.stationName,
  });
}

void main() {
  group('StationInsightsCalculator Unit Tests', () {
    test('Calculates station analytics, best mileage, and lowest price correctly', () {
      final now = DateTime(2026, 10, 1);

      // Entry 1 at Padma (20L @ 130 = 2600)
      // Entry 2 at Padma (25L @ 132 = 3300) -> achieved 14.5 km/L on Padma fuel from entry 1
      // Entry 3 at Meghna (30L @ 125 = 3750) -> achieved 12.0 km/L on Padma fuel from entry 2
      // Entry 4 at Meghna (25L @ 126 = 3150) -> achieved 11.0 km/L on Meghna fuel from entry 3
      final entries = [
        MockFuelEntry(
          id: 'e1',
          entryDateTime: now,
          quantity: 20.0,
          pricePerUnit: 130.0,
          totalCost: 2600.0,
          stationName: 'Padma Oil',
        ),
        MockFuelEntry(
          id: 'e2',
          entryDateTime: now.add(const Duration(days: 5)),
          quantity: 25.0,
          pricePerUnit: 132.0,
          totalCost: 3300.0,
          stationName: 'Padma Oil',
        ),
        MockFuelEntry(
          id: 'e3',
          entryDateTime: now.add(const Duration(days: 10)),
          quantity: 30.0,
          pricePerUnit: 125.0,
          totalCost: 3750.0,
          stationName: 'Meghna Petroleum',
        ),
        MockFuelEntry(
          id: 'e4',
          entryDateTime: now.add(const Duration(days: 15)),
          quantity: 25.0,
          pricePerUnit: 126.0,
          totalCost: 3150.0,
          stationName: 'meghna petroleum', // lowercase to test normalization
        ),
      ];

      final entryStats = {
        'e1': const CalculatedEntryStats(entryId: 'e1', calculatedMileage: null),
        'e2': const CalculatedEntryStats(entryId: 'e2', calculatedMileage: 14.5), // Padma fuel
        'e3': const CalculatedEntryStats(entryId: 'e3', calculatedMileage: 13.5), // Padma fuel
        'e4': const CalculatedEntryStats(entryId: 'e4', calculatedMileage: 11.0), // Meghna fuel
      };

      final summary = StationInsightsCalculator.calculate(
        entries: entries,
        entryStats: entryStats,
        economyUnit: 'km/L',
      );

      expect(summary.stations.length, 2);

      // Verify Padma:
      // Volume = 45L, Spend = 5900, Avg Price = 5900 / 45 ≈ 131.11, Visits = 2
      final padma = summary.stations.firstWhere((s) => s.stationName.contains('Padma'));
      expect(padma.visitCount, 2);
      expect(padma.totalVolume, 45.0);
      expect(padma.totalSpend, 5900.0);
      expect(padma.minPrice, 130.0);
      expect(padma.maxPrice, 132.0);
      expect(padma.averagePrice, closeTo(131.11, 0.05));
      expect(padma.averageMileage, closeTo(14.0, 0.01)); // (14.5 + 13.5) / 2
      expect(padma.isBestMileage, isTrue);

      // Verify Meghna:
      // Volume = 55L, Spend = 6900, Avg Price = 6900 / 55 ≈ 125.45, Visits = 2
      final meghna = summary.stations.firstWhere((s) => s.stationName.toLowerCase().contains('meghna'));
      expect(meghna.visitCount, 2);
      expect(meghna.totalVolume, 55.0);
      expect(meghna.totalSpend, 6900.0);
      expect(meghna.minPrice, 125.0);
      expect(meghna.maxPrice, 126.0);
      expect(meghna.averagePrice, closeTo(125.45, 0.05));
      expect(meghna.averageMileage, 11.0);
      expect(meghna.isLowestPrice, isTrue);

      // Best and Lowest Summary targets
      expect(summary.bestMileageStation?.stationName, contains('Padma'));
      expect(summary.lowestPriceStation?.stationName.toLowerCase(), contains('meghna'));
      expect(summary.vehicleAverageMileage, closeTo(13.0, 0.01)); // (14.5 + 13.5 + 11.0) / 3
    });

    test('Returns empty summary cleanly when entries list is empty', () {
      final summary = StationInsightsCalculator.calculate(
        entries: [],
        entryStats: {},
      );

      expect(summary.isEmpty, isTrue);
      expect(summary.stations, isEmpty);
      expect(summary.bestMileageStation, isNull);
      expect(summary.lowestPriceStation, isNull);
    });
  });
}
