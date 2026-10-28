enum DocumentExpiryStatus {
  valid,
  expiringSoon,
  expired,
  noExpiry,
}

class DocumentExpiryCalculator {
  /// Evaluates the document's expiry status against a given [referenceDate] (defaults to now).
  static DocumentExpiryStatus calculateStatus({
    required DateTime? expiryDate,
    int warningDays = 30,
    DateTime? referenceDate,
  }) {
    if (expiryDate == null) {
      return DocumentExpiryStatus.noExpiry;
    }

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final differenceInDays = expiryDay.difference(today).inDays;

    if (differenceInDays < 0) {
      return DocumentExpiryStatus.expired;
    } else if (differenceInDays <= warningDays) {
      return DocumentExpiryStatus.expiringSoon;
    } else {
      return DocumentExpiryStatus.valid;
    }
  }

  /// Calculates days until expiry.
  /// Returns negative value if already expired, 0 if expires today, positive if in future, null if no expiry.
  static int? getDaysUntilExpiry({
    required DateTime? expiryDate,
    DateTime? referenceDate,
  }) {
    if (expiryDate == null) return null;

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    return expiryDay.difference(today).inDays;
  }

  /// Parses comma-separated reminder days e.g. "30,15,7,1" into a sorted list of integers.
  static List<int> parseReminderDays(String? reminderDaysBefore) {
    if (reminderDaysBefore == null || reminderDaysBefore.trim().isEmpty) {
      return [30, 15, 7, 1];
    }

    return reminderDaysBefore
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d > 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
  }

  /// Calculates upcoming notification trigger timestamps for the reminder schedule.
  /// Scheduled at 9:00 AM on the day of reminder.
  static List<({int daysBefore, DateTime scheduledDate})> getNotificationSchedule({
    required DateTime expiryDate,
    required List<int> reminderDays,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final schedule = <({int daysBefore, DateTime scheduledDate})>[];

    for (final days in reminderDays) {
      final targetDate = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day - days,
        9, // 9:00 AM
        0,
      );

      if (targetDate.isAfter(now)) {
        schedule.add((daysBefore: days, scheduledDate: targetDate));
      }
    }

    return schedule;
  }

  /// Formats human-readable status text.
  static String formatStatusLabel({
    required DocumentExpiryStatus status,
    required int? daysRemaining,
  }) {
    switch (status) {
      case DocumentExpiryStatus.expired:
        final days = (daysRemaining ?? 0).abs();
        if (days == 0) return 'Expired today';
        if (days == 1) return 'Expired yesterday';
        return 'Expired $days days ago';

      case DocumentExpiryStatus.expiringSoon:
        final days = daysRemaining ?? 0;
        if (days == 0) return 'Expires today';
        if (days == 1) return 'Expires tomorrow';
        return 'Expires in $days days';

      case DocumentExpiryStatus.valid:
        final days = daysRemaining ?? 0;
        return 'Valid ($days days left)';

      case DocumentExpiryStatus.noExpiry:
        return 'Lifetime / No Expiry';
    }
  }
}
