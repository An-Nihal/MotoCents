enum AnomalySeverity {
  warning, // 15% - 25% drop
  critical, // > 25% drop
}

class MileageDropAlert {
  final String entryId;
  final double currentMileage;
  final double baselineMileage;
  final double dropPercentage;
  final AnomalySeverity severity;
  final String primaryTip;
  final List<String> actionableTips;
  final DateTime entryDate;
  final String economyUnit;

  const MileageDropAlert({
    required this.entryId,
    required this.currentMileage,
    required this.baselineMileage,
    required this.dropPercentage,
    required this.severity,
    required this.primaryTip,
    required this.actionableTips,
    required this.entryDate,
    required this.economyUnit,
  });

  String get formattedDrop => '-${dropPercentage.toStringAsFixed(1)}%';
}
