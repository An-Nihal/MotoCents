import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/fuel/domain/mileage_calculator.dart';
import 'package:motocents/features/smart/domain/mileage_anomaly.dart';
import 'package:motocents/features/smart/domain/mileage_drop_detector.dart';

class MockFuelEntry {
  final String id;
  final DateTime entryDateTime;

  MockFuelEntry({required this.id, required this.entryDateTime});
}

void main() {
  group('MileageDropDetector Unit Tests', () {
    test('Returns null when mileage drop is within normal bounds (< 15%)', () {
      final alert = MileageDropDetector.checkEntryForAnomaly(
        entryId: 'entry-1',
        currentMileage: 11.2,
        previousMileages: [12.0, 11.8, 12.2], // baseline = 12.0
        entryDate: DateTime(2026, 10, 20),
        economyUnit: 'km/L',
      );

      // (12.0 - 11.2) / 12.0 = 6.67% drop (< 15%)
      expect(alert, isNull);
    });

    test('Triggers warning alert when mileage drop is between 15% and 25%', () {
      final alert = MileageDropDetector.checkEntryForAnomaly(
        entryId: 'entry-2',
        currentMileage: 9.8,
        previousMileages: [12.0, 12.0, 12.0], // baseline = 12.0
        entryDate: DateTime(2026, 10, 20),
        economyUnit: 'km/L',
      );

      // (12.0 - 9.8) / 12.0 = 18.33% drop
      expect(alert, isNotNull);
      expect(alert!.severity, AnomalySeverity.warning);
      expect(alert.dropPercentage, closeTo(18.33, 0.1));
      expect(alert.formattedDrop, '-18.3%');
      expect(alert.actionableTips.length, greaterThanOrEqualTo(4));
      expect(alert.primaryTip, contains('Check tyre pressure'));
    });

    test('Triggers critical alert when mileage drop is greater than 25%', () {
      final alert = MileageDropDetector.checkEntryForAnomaly(
        entryId: 'entry-3',
        currentMileage: 8.0,
        previousMileages: [12.0, 12.0], // baseline = 12.0
        entryDate: DateTime(2026, 10, 20),
        economyUnit: 'km/L',
      );

      // (12.0 - 8.0) / 12.0 = 33.33% drop
      expect(alert, isNotNull);
      expect(alert!.severity, AnomalySeverity.critical);
      expect(alert.dropPercentage, closeTo(33.33, 0.1));
    });

    test('Correctly handles L/100km economy unit (higher value means worse efficiency)', () {
      // In L/100km, 7.0 baseline -> 8.5 current means fuel consumption increased by 21.4%
      final alert = MileageDropDetector.checkEntryForAnomaly(
        entryId: 'entry-4',
        currentMileage: 8.5,
        previousMileages: [7.0, 7.0],
        entryDate: DateTime(2026, 10, 20),
        economyUnit: 'L/100km',
      );

      expect(alert, isNotNull);
      expect(alert!.dropPercentage, closeTo(21.42, 0.1));
      expect(alert.severity, AnomalySeverity.warning);
    });

    test('Uses rolling average window of max last 5 entries', () {
      final alert = MileageDropDetector.checkEntryForAnomaly(
        entryId: 'entry-5',
        currentMileage: 9.0,
        // First 3 entries are low (8.0), but last 5 entries are high (12.0)
        previousMileages: [8.0, 8.0, 8.0, 12.0, 12.0, 12.0, 12.0, 12.0],
        entryDate: DateTime(2026, 10, 20),
        economyUnit: 'km/L',
      );

      // Baseline should be 12.0 (from last 5), drop is (12 - 9) / 12 = 25.0%
      expect(alert, isNotNull);
      expect(alert!.baselineMileage, 12.0);
      expect(alert.dropPercentage, closeTo(25.0, 0.1));
    });

    test('detectLatestAnomaly identifies anomaly on final entry of sequence', () {
      final entries = [
        MockFuelEntry(id: 'f1', entryDateTime: DateTime(2026, 9, 1)),
        MockFuelEntry(id: 'f2', entryDateTime: DateTime(2026, 9, 10)),
        MockFuelEntry(id: 'f3', entryDateTime: DateTime(2026, 9, 20)),
        MockFuelEntry(id: 'f4', entryDateTime: DateTime(2026, 10, 1)),
      ];

      final entryStats = {
        'f1': const CalculatedEntryStats(entryId: 'f1', calculatedMileage: 14.0),
        'f2': const CalculatedEntryStats(entryId: 'f2', calculatedMileage: 14.2),
        'f3': const CalculatedEntryStats(entryId: 'f3', calculatedMileage: 13.8),
        'f4': const CalculatedEntryStats(entryId: 'f4', calculatedMileage: 10.5), // Drop!
      };

      final latestAlert = MileageDropDetector.detectLatestAnomaly(
        entries: entries,
        entryStats: entryStats,
        economyUnit: 'km/L',
      );

      expect(latestAlert, isNotNull);
      expect(latestAlert!.entryId, 'f4');
      expect(latestAlert.currentMileage, 10.5);
      expect(latestAlert.dropPercentage, greaterThan(20.0));
    });
  });
}
