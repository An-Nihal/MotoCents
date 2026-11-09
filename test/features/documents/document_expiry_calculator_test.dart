import 'package:flutter_test/flutter_test.dart';
import 'package:motocents/features/documents/domain/document_expiry_calculator.dart';

void main() {
  group('DocumentExpiryCalculator', () {
    final referenceDate = DateTime(2026, 10, 28, 12, 0);

    test('calculateStatus correctly classifies expiry states', () {
      // Null expiry
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: null,
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.noExpiry),
      );

      // Expired (yesterday)
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: DateTime(2026, 10, 27),
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.expired),
      );

      // Expiring today (0 days) -> expiringSoon
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: DateTime(2026, 10, 28),
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.expiringSoon),
      );

      // Expiring in 15 days -> expiringSoon
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: DateTime(2026, 11, 12),
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.expiringSoon),
      );

      // Expiring in exactly 30 days -> expiringSoon
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: DateTime(2026, 11, 27),
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.expiringSoon),
      );

      // Expiring in 60 days -> valid
      expect(
        DocumentExpiryCalculator.calculateStatus(
          expiryDate: DateTime(2026, 12, 27),
          referenceDate: referenceDate,
        ),
        equals(DocumentExpiryStatus.valid),
      );
    });

    test('getDaysUntilExpiry returns correct offset', () {
      expect(
        DocumentExpiryCalculator.getDaysUntilExpiry(
          expiryDate: null,
          referenceDate: referenceDate,
        ),
        isNull,
      );

      expect(
        DocumentExpiryCalculator.getDaysUntilExpiry(
          expiryDate: DateTime(2026, 10, 25),
          referenceDate: referenceDate,
        ),
        equals(-3),
      );

      expect(
        DocumentExpiryCalculator.getDaysUntilExpiry(
          expiryDate: DateTime(2026, 10, 28),
          referenceDate: referenceDate,
        ),
        equals(0),
      );

      expect(
        DocumentExpiryCalculator.getDaysUntilExpiry(
          expiryDate: DateTime(2026, 10, 31),
          referenceDate: referenceDate,
        ),
        equals(3),
      );
    });

    test('parseReminderDays correctly cleans and sorts days', () {
      expect(
        DocumentExpiryCalculator.parseReminderDays(' 30, 15, 7, 1 '),
        equals([30, 15, 7, 1]),
      );

      expect(
        DocumentExpiryCalculator.parseReminderDays('1, 15, 30, 7, 15, -5, abc'),
        equals([30, 15, 7, 1]),
      );

      expect(
        DocumentExpiryCalculator.parseReminderDays(null),
        equals([30, 15, 7, 1]),
      );
    });

    test('getNotificationSchedule schedules future reminders at 9 AM', () {
      final expiryDate = DateTime(2026, 11, 20); // 23 days from Oct 28
      final reminderDays = [30, 15, 7, 1];

      final schedule = DocumentExpiryCalculator.getNotificationSchedule(
        expiryDate: expiryDate,
        reminderDays: reminderDays,
        referenceDate: referenceDate,
      );

      // 30 days before is Oct 21 (which is in the past), so it should not be scheduled.
      // 15 days before is Nov 5 at 09:00 AM (future)
      // 7 days before is Nov 13 at 09:00 AM (future)
      // 1 day before is Nov 19 at 09:00 AM (future)
      expect(schedule.length, equals(3));
      expect(schedule[0].daysBefore, equals(15));
      expect(schedule[0].scheduledDate, equals(DateTime(2026, 11, 5, 9, 0)));
      expect(schedule[1].daysBefore, equals(7));
      expect(schedule[2].daysBefore, equals(1));
    });

    test('formatStatusLabel provides user friendly strings', () {
      expect(
        DocumentExpiryCalculator.formatStatusLabel(
          status: DocumentExpiryStatus.expired,
          daysRemaining: -4,
        ),
        equals('Expired 4 days ago'),
      );

      expect(
        DocumentExpiryCalculator.formatStatusLabel(
          status: DocumentExpiryStatus.expiringSoon,
          daysRemaining: 1,
        ),
        equals('Expires tomorrow'),
      );

      expect(
        DocumentExpiryCalculator.formatStatusLabel(
          status: DocumentExpiryStatus.expiringSoon,
          daysRemaining: 12,
        ),
        equals('Expires in 12 days'),
      );

      expect(
        DocumentExpiryCalculator.formatStatusLabel(
          status: DocumentExpiryStatus.valid,
          daysRemaining: 120,
        ),
        equals('Valid (120 days left)'),
      );

      expect(
        DocumentExpiryCalculator.formatStatusLabel(
          status: DocumentExpiryStatus.noExpiry,
          daysRemaining: null,
        ),
        equals('Lifetime / No Expiry'),
      );
    });
  });
}
