enum ReminderStatus {
  ok,
  dueSoon,
  overdue,
}

class ServiceReminderProgress {
  final double progressRatio; // 0.0 to 1.0 (clamped for UI progress bar)
  final double rawProgressRatio; // can be > 1.0 if overdue
  final ReminderStatus status;
  final double? remainingDistance;
  final int? remainingDays;
  final DateTime? estimatedDueDate;
  final String statusDescription;

  const ServiceReminderProgress({
    required this.progressRatio,
    required this.rawProgressRatio,
    required this.status,
    this.remainingDistance,
    this.remainingDays,
    this.estimatedDueDate,
    required this.statusDescription,
  });
}

class ReminderCalculator {
  /// Calculates daily average distance driven by the vehicle.
  /// Uses difference between current odometer and initial odometer,
  /// divided by days since vehicle created / first recorded date.
  /// Falls back to 25 km/day if insufficient data (< 1 day or 0 distance).
  static double calculateAverageDailyDistance({
    required double currentOdometer,
    required double initialOdometer,
    required DateTime baselineDate,
    DateTime? currentDate,
    double fallbackDailyDistance = 25.0,
  }) {
    final now = currentDate ?? DateTime.now();
    final daysElapsed = now.difference(baselineDate).inDays;
    final totalDistance = currentOdometer - initialOdometer;

    if (daysElapsed >= 3 && totalDistance > 0) {
      final avg = totalDistance / daysElapsed;
      return avg > 0.5 ? avg : fallbackDailyDistance;
    }
    return fallbackDailyDistance;
  }

  /// Calculates the progress, remaining distance/days, estimated due date,
  /// and status for a service reminder.
  static ServiceReminderProgress calculateProgress({
    required String reminderType, // 'distance', 'time', 'both'
    required double currentOdometer,
    required double lastServiceOdometer,
    required DateTime lastServiceDate,
    double? intervalDistance,
    int? intervalMonths,
    double averageDailyDistance = 25.0,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();

    double? distanceProgress;
    double? timeProgress;
    double? remainingDist;
    int? remainingDays;
    DateTime? estimatedDate;

    // 1. Distance Calculation
    if ((reminderType == 'distance' || reminderType == 'both') &&
        intervalDistance != null &&
        intervalDistance > 0) {
      final distanceSinceLast = currentOdometer - lastServiceOdometer;
      distanceProgress = distanceSinceLast / intervalDistance;
      remainingDist = intervalDistance - distanceSinceLast;

      // Estimate due date using average daily distance
      if (averageDailyDistance > 0) {
        final daysUntilDue = (remainingDist / averageDailyDistance).round();
        estimatedDate = now.add(Duration(days: daysUntilDue));
      }
    }

    // 2. Time Calculation
    if ((reminderType == 'time' || reminderType == 'both') &&
        intervalMonths != null &&
        intervalMonths > 0) {
      final totalDaysInInterval = intervalMonths * 30.4375; // average month days
      final daysSinceLast = now.difference(lastServiceDate).inDays;
      timeProgress = daysSinceLast / totalDaysInInterval;

      final dueDate = DateTime(
        lastServiceDate.year,
        lastServiceDate.month + intervalMonths,
        lastServiceDate.day,
      );
      remainingDays = dueDate.difference(now).inDays;

      // If reminder is 'time' only, estimatedDueDate is the exact due date
      if (reminderType == 'time') {
        estimatedDate = dueDate;
      } else if (reminderType == 'both') {
        // Whichever comes first: earlier of estimated distance date or time dueDate
        if (estimatedDate != null && estimatedDate.isAfter(dueDate)) {
          estimatedDate = dueDate;
        }
      }
    }

    // Combine according to reminderType
    double rawRatio = 0.0;
    if (reminderType == 'distance') {
      rawRatio = distanceProgress ?? 0.0;
    } else if (reminderType == 'time') {
      rawRatio = timeProgress ?? 0.0;
    } else {
      // 'both': whichever is higher progress (comes first)
      rawRatio = [distanceProgress ?? 0.0, timeProgress ?? 0.0]
          .reduce((a, b) => a > b ? a : b);
    }

    final double clampedRatio = rawRatio.clamp(0.0, 1.0);

    // Determine Status
    ReminderStatus status = ReminderStatus.ok;
    String description = '';

    if (rawRatio >= 1.0) {
      status = ReminderStatus.overdue;
      if (remainingDist != null && remainingDist < 0) {
        description = 'Overdue by ${(-remainingDist).toStringAsFixed(0)} km';
      } else if (remainingDays != null && remainingDays < 0) {
        description = 'Overdue by ${-remainingDays} days';
      } else {
        description = 'Service overdue';
      }
    } else if (rawRatio >= 0.85 || (remainingDays != null && remainingDays <= 14)) {
      status = ReminderStatus.dueSoon;
      if (remainingDist != null && remainingDist > 0) {
        description = 'Due in ${remainingDist.toStringAsFixed(0)} km';
      } else if (remainingDays != null) {
        description = 'Due in $remainingDays days';
      } else {
        description = 'Due soon';
      }
    } else {
      status = ReminderStatus.ok;
      if (remainingDist != null && remainingDist > 0) {
        description = '${remainingDist.toStringAsFixed(0)} km left';
      } else if (remainingDays != null && remainingDays > 0) {
        description = '$remainingDays days left';
      } else {
        description = 'Up to date';
      }
    }

    return ServiceReminderProgress(
      progressRatio: clampedRatio,
      rawProgressRatio: rawRatio,
      status: status,
      remainingDistance: remainingDist,
      remainingDays: remainingDays,
      estimatedDueDate: estimatedDate,
      statusDescription: description,
    );
  }
}
