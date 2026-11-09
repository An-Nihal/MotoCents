import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/service/domain/reminder_calculator.dart';

void main() {
  group('ReminderCalculator', () {
    test('calculateAverageDailyDistance computes rate from historical data', () {
      final baseline = DateTime(2026, 1, 1);
      final current = DateTime(2026, 1, 31); // 30 days elapsed

      final daily = ReminderCalculator.calculateAverageDailyDistance(
        currentOdometer: 11500.0,
        initialOdometer: 10000.0, // 1500 km in 30 days = 50 km/day
        baselineDate: baseline,
        currentDate: current,
      );

      expect(daily, 50.0);
    });

    test('calculateAverageDailyDistance falls back when elapsed days < 3', () {
      final baseline = DateTime(2026, 1, 1);
      final current = DateTime(2026, 1, 2); // 1 day

      final daily = ReminderCalculator.calculateAverageDailyDistance(
        currentOdometer: 10100.0,
        initialOdometer: 10000.0,
        baselineDate: baseline,
        currentDate: current,
        fallbackDailyDistance: 30.0,
      );

      expect(daily, 30.0);
    });

    test('Distance reminder: progress, remaining distance, and estimated due date', () {
      final now = DateTime(2026, 6, 1);
      final lastDate = DateTime(2026, 5, 1);

      final progress = ReminderCalculator.calculateProgress(
        reminderType: 'distance',
        currentOdometer: 12450.0,
        lastServiceOdometer: 10000.0,
        lastServiceDate: lastDate,
        intervalDistance: 3000.0,
        averageDailyDistance: 50.0,
        currentDate: now,
      );

      // Distance driven = 2450 km / 3000 = ~81.67%
      expect(progress.rawProgressRatio, closeTo(0.816, 0.01));
      expect(progress.progressRatio, closeTo(0.816, 0.01));
      expect(progress.remainingDistance, 550.0);
      expect(progress.status, ReminderStatus.ok);

      // Estimated due date: 550 km / 50 km/day = 11 days from now
      expect(progress.estimatedDueDate, isNotNull);
      final daysDiff = progress.estimatedDueDate!.difference(now).inDays;
      expect(daysDiff, 11);
    });

    test('Distance reminder: overdue status when current > due odometer', () {
      final progress = ReminderCalculator.calculateProgress(
        reminderType: 'distance',
        currentOdometer: 13200.0,
        lastServiceOdometer: 10000.0,
        lastServiceDate: DateTime.now(),
        intervalDistance: 3000.0,
      );

      expect(progress.status, ReminderStatus.overdue);
      expect(progress.rawProgressRatio, greaterThan(1.0));
      expect(progress.progressRatio, 1.0); // clamped
      expect(progress.remainingDistance, -200.0);
    });

    test('Time reminder: due soon within 14 days', () {
      final lastDate = DateTime(2026, 1, 1);
      final now = DateTime(2026, 3, 20); // Interval 3 months (due April 1st)

      final progress = ReminderCalculator.calculateProgress(
        reminderType: 'time',
        currentOdometer: 10000.0,
        lastServiceOdometer: 10000.0,
        lastServiceDate: lastDate,
        intervalMonths: 3,
        currentDate: now,
      );

      // Remaining days: April 1 - March 20 = 12 days (<= 14 days)
      expect(progress.status, ReminderStatus.dueSoon);
      expect(progress.remainingDays, 12);
    });

    test('Hybrid "both" reminder: picks whichever trigger comes first', () {
      final now = DateTime(2026, 3, 1);
      final lastDate = DateTime(2026, 2, 1);

      // Distance is at 95% progress (due soon), while time is only at 33% (1 of 3 months)
      final progress = ReminderCalculator.calculateProgress(
        reminderType: 'both',
        currentOdometer: 12850.0, // 2850 / 3000 = 95%
        lastServiceOdometer: 10000.0,
        lastServiceDate: lastDate,
        intervalDistance: 3000.0,
        intervalMonths: 3,
        currentDate: now,
      );

      expect(progress.status, ReminderStatus.dueSoon);
      expect(progress.rawProgressRatio, closeTo(0.95, 0.01));
    });
  });
}
